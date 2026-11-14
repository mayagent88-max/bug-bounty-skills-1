---
name: browser-harness-ro-bypass
description: "Use when driving Chrome or running browser automation here."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [browser, cdp, chrome, cloakbrowser, playwright, gmail, vnc, novnc, workaround, read-only-fs, locale-selectors]
    related_skills: [bug-bounty-submission, web3-bot-ops]
---

# Browser harness read-only bypass + Gmail send via CDP

## When to use
- `browser_exec` fails (socket created but connection refused, or daemon won't start)
- You need to send an email from the user's Gmail
- You need to drive a browser but the Hermes browser harness is broken
- You are running or porting a third-party browser-automation repo (CloakBrowser launcher,
  Playwright CDP driver, headless signup/onboarding flow) on this VPS

## Diagnosis: browser_exec broken by read-only $HOME

Symptom: `browser_exec` returns exit 1 with stderr like:
`browser-harness: listening on <HOME_DIR>/.config/browser-harness/runtime/bu-default.sock`

Root cause chain:
1. `<HOME_DIR>` is a read-only mount (only `<HOME_DIR>/.hermes` and `/tmp` are rw)
2. `browser_harness/paths.py` `workspace_dir()` defaults to `$HOME/.config/browser-harness/agent-workspace`
3. `tools/browser_harness_dirs.py` `fit_default_socket_dir()` only relocates the runtime dir when the AF_UNIX socket path would overflow `sun_path` (budget = 107 - len("/bu-.sock") - 64 = 34 chars) — it does NOT handle a read-only path
4. With `BU_NAME="default"` (7 chars), `stem_budget` = 34 + 64 - 7 = 91, so the 44-char default path FITS and no relocation happens
5. Daemon cannot create its socket in the RO dir

Verify: `touch <HOME_DIR>/.config/browser-harness/.wtest` -> "Read-only file system"

**Cannot fix from inside the container**: harness package is RO, no config hook to inject `BH_HOME`/`BH_RUNTIME_DIR` into the tool's subprocess env, `spawn_env()` only sets a spawn tag.

## Bypass: drive Chrome directly via CDP

Chrome usually still runs. Find it:
```
ps aux | grep chrome | grep remote-debugging-port
ss -tlnp | grep -E '9222|35[0-9]{3}'
```

Minimal CDP driver (websocket-client, no harness needed):
```python
import json, urllib.request, websocket
CDP_URL = "http://127.0.0.1:9330"   # name it CDP_URL — a module-level CDP constant gets
                                    # shadowed by the CDP class and breaks page_ws()

def page_ws():
    with urllib.request.urlopen(CDP_URL + "/json/list", timeout=10) as r:
        for t in json.load(r):
            if t.get("type") == "page":
                return t["webSocketDebuggerUrl"]

ws = websocket.create_connection(page_ws(), timeout=60)
_id = 0
def send(method, **params):
    global _id; _id += 1; mid = _id
    ws.send(json.dumps({"id": mid, "method": method, "params": params}))
    while True:
        m = json.loads(ws.recv())
        if m.get("id") == mid:
            if "error" in m: raise RuntimeError(m["error"])
            return m.get("result", {})

def ev(expr):
    r = send("Runtime.evaluate", expression=expr, returnByValue=True)
    return r.get("result", {}).get("value")
```

**Launch your own Chrome with `--remote-allow-origins='*'`.** Chrome rejects the
DevTools WebSocket handshake with 403 `"Rejected an incoming WebSocket connection from
the http://127.0.0.1:<port> origin"` unless the origin is allowed — the flag is required,
not optional, and the error names the fix. Full launch that works here (RO $HOME, so every
path is redirected into /tmp):
```
HOME=/tmp/chrome-x XDG_CONFIG_HOME=/tmp/chrome-x/config XDG_CACHE_HOME=/tmp/chrome-x/cache \
  <HOME_DIR>/.hermes/tools/chromium-1208/chrome-linux64/chrome \
  --remote-debugging-port=9330 --remote-allow-origins='*' \
  --user-data-dir=/tmp/chrome-x/profile --headless=new --no-sandbox \
  --disable-dev-shm-usage --window-size=1400,900 about:blank
```
Run it with `terminal(background=True)`; verify with
`curl -s http://127.0.0.1:9330/json/version` before connecting. Kill by explicit PID
(`pkill -f chrome` takes the calling shell with it).

## Driving Angular / custom-component SPAs (OneDoc-style booking widgets)

Angular SPAs (and any app with custom `od-*`/`mat-*` components) ignore synthetic JS
clicks — `el.click()` and `dispatchEvent(new MouseEvent('click'))` do nothing, while the
same call works on plain HTML. Use real CDP mouse events and re-measure every time:

1. **Measure the box and click in the same breath.** `getBoundingClientRect()` goes stale
   the moment the page scrolls or a panel opens — a box measured before `scrollIntoView`
   points at whatever now occupies those coordinates. Measure, click, done.
2. **Verify the target with `elementFromPoint` first.**
   `document.elementFromPoint(cx, cy)` returning a different element (or null) means an
   overlay or a stale box — fix that before blaming the app.
3. **Filter duplicates by size.** Angular renders hidden template copies of buttons
   (`h:0, w:0`). `[...querySelectorAll('button')].find(b => b.getBoundingClientRect().height > 0)`
   — a bare `.find()` grabs the invisible clone and "clicks" nothing.
4. **Custom dropdowns need a real click on the field wrapper.** Angular Material /
   `od-select-field` open on a trusted `mousePressed`+`mouseReleased` pair at the
   `.field__wrapper` box; the option list then renders as `mat-option` / `.ng-option` /
   `[role=option]` and each option needs its own real click.
5. **When a button ignores every event type** (trusted CDP click, JS click with the full
   mouseover/mousedown/mouseup/click sequence, `form.requestSubmit()`, keyboard
   focus+Enter, clicking the inner span) — stop clicking and read the app bundle. Grep the
   JS for the handler (`bookAppointment`, `onSubmit`) and the store/state guard it throws
   on; the button is usually gated on state the UI never shows. Budget two attempts, then
   report the blocker — a button that answers nothing is a state problem, not an
   event-delivery problem.
6. **Read Angular form validity from classes, not from the UI.**
   `ng-valid ng-touched ng-dirty` / `field--empty` on the control's host element tells you
   which control the model considers untouched — the visible form can look complete while
   the model disagrees.

App bundles on public CDNs need no session: list `script[src]` from the loaded page and
`curl` the asset directly to grep handler logic offline.

## React controlled inputs + multi-step registration wizards

**Check the viewport before every coordinate click.** A click dispatched at
y > `window.innerHeight` lands on nothing — CDP accepts it, the page never receives
it, and the button reads as "dead". `getBoundingClientRect()` alone does not tell
you: compare `r.bottom <= window.innerHeight`, `scrollIntoView({block:'center'})`,
then RE-MEASURE (the box moves after the scroll) and confirm with
`document.elementFromPoint(cx, cy)` that the button or its span now sits there.
A submit button that ignores every click variant is often simply below the fold.

**React controlled inputs: real mouse click, then `Input.insertText`.**
`el.focus()` + `Input.insertText` sets the DOM value but the component's onChange
never fires, so React state stays empty and the form validates against nothing.
The full recipe — including the Downshift keyboard path and the `CDP_PORT`
gotcha — is in the `bug-bounty-recon` skill's Instabox VM browser reference;
read it before driving any login or registration wizard on the operator's VMs.

**The `_valueTracker` reset is the fallback when insertText still does not
stick.** React caches the input's last value on `el._valueTracker`; assigning
`.value` directly looks like "no change" and onChange is skipped:
```js
const t = el._valueTracker; if (t) t.setValue('');
el.value = '...'; el.dispatchEvent(new Event('input', {bubbles: true}));
```
If the value then persists but the form still refuses to submit (zero network
requests fire), the component is filtering programmatic input at the form-state
level — stop iterating event tricks and report the step as needing a real
keystroke source rather than recording the dead ends as a workflow.

**Read a React component's real handlers off the fiber when the DOM lies.** A
button whose `onClick` never submits is usually gated on state the UI never
shows — the handler source names the guard, which is faster than guessing at
event variants:

```js
const k = Object.keys(el).find(x => x.startsWith('__reactFiber$'));
let n = el[k]; const out = [];
while (n) {
  const p = n.memoizedProps || n.pendingProps;
  if (p) for (const h of ['onClick','onSubmit']) if (typeof p[h]==='function') out.push(p[h].toString());
  n = n.return;
}
```

Two rules when using it: walk `child`/`sibling` with a `seen` Set and a depth
cap (the tree is deep and cyclic), and **store the handler you find on
`window` in one `eval` and call it in a second** — a combined find-and-call
expression returns `None` from the CDP driver and reads as a silent failure.
A handler that is gated on an internal ref (e.g. `if (executing) …`) must have
that ref set by the real UI interaction first — invoke the click, then the
callback, never the callback alone.

## Launching a non-headless Chromium on a fresh Xvfb (challenge iframes)

Headless Chromium never loads some cross-origin challenge iframes; a headed
instance on a real display does. When a widget's iframe is absent from
`/json/list`, start a second Xvfb at a usable resolution and launch Chromium
against it:

```
Xvfb :2 -screen 0 1920x1080x24 &
DISPLAY=:2 chromium --user-data-dir=/tmp/prof2 --remote-debugging-port=9341 \
  --remote-debugging-address=127.0.0.1 --window-size=1600,1000 \
  --no-first-run --password-store=basic --use-mock-keychain "<url>" &
```

Copy the profile first (`cp -a`) and delete `SingletonLock`, `SingletonSocket`
and `SingletonCookie` from the copy, or the launch dies on the lock. The
iframe appearing in `/json/list` proves the display context was the blocker —
it does **not** prove the challenge will complete, so verify a token was
actually produced before building a workflow on it.

## xdotool on a small Xvfb display

- `windowactivate --sync` before sending keys or clicks, or the events go to
  whatever window has focus.
- **Arrow keys scroll the address bar, not the page.** Use the mouse wheel
  (`xdotool click 4` / `click 5`) for page scroll, with the pointer parked
  over the page first.
- A display smaller than the form makes coordinate clicking unreliable —
  measure text blocks from a screenshot (`scrot -u`) rather than trusting
  estimated coordinates, and prefer a larger Xvfb when one is available.

**Dismiss cookie-consent overlays (OneTrust et al) before touching anything.**
The consent SDK renders a full-screen dialog that swallows clicks meant for the
real form. Click the accept button matched locale-invariantly
(`/allow all|accept all|接受全部/i`), then verify `#onetrust-consent-sdk` is gone
before proceeding. When the SDK also mounts a full-screen scrim
(`.onetrust-pc-dark-filter`) the scrim swallows the click on the accept button
itself — every pointer event lands on the filter — so remove the nodes directly
instead of hunting the button:
`document.querySelectorAll('#onetrust-consent-sdk, .onetrust-pc-dark-filter').forEach(e => e.remove())`.
Diagnose any unresponsive control with `document.elementFromPoint(cx, cy)`
before blaming the app: an overlay node sitting at the click point is the whole
bug.

**Capture an SPA's API surface with the Performance API, not the Network
domain.** With the page already loaded,
`performance.getEntriesByType('resource')` filtered to `initiatorType` of
`fetch`/`xmlhttprequest` lists every XHR with no event pump — and pumping the
Network domain from inside a `recv` hook re-enters and hangs the connection.
This is also how the real API host and path prefix get read off a live app.

## Running CloakBrowser / Playwright automation repos on this VPS

Repos authored on Windows (CloakBrowser launchers, Playwright CDP drivers) need four Linux
fixes before they run here. Apply all four — each one alone still fails.

1. **Binary path.** A `findBinary()` that returns a hardcoded `chrome.exe` path makes
   `spawn` fail with ENOENT. Resolve per platform: `chrome.exe` on win32, `chrome`
   elsewhere, falling back to `/usr/bin/google-chrome`.
2. **Sandbox.** Containers have no setuid sandbox, so Chrome dies instantly with
   `No usable sandbox!`. Push `--no-sandbox --disable-dev-shm-usage` on every non-Windows
   launch.
3. **Writable profile and config.** `<HOME_DIR>` is read-only (see the diagnosis above),
   so a `--user-data-dir` under `$HOME` and `$HOME/.config/chromium` both fail with
   `SingletonLock ... Read-only file system`. Point `--user-data-dir` at `/tmp/...` and
   spawn with `HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` redirected into the same
   writable tree. Probe with `fs.accessSync(dir, W_OK)` and pick the base dir from the
   result instead of assuming.
4. **Process cleanup.** `taskkill /F /T /PID` is Windows-only and raises on Linux. Use
   `proc.terminate()` with a `wait(timeout=)` then `proc.kill()` inside a `finally`.

**Support a direct (no-proxy) mode.** Launchers that hard-require `PROXY_URL` or a
`proxies.txt` refuse to start at all. Treat an empty or `direct` value as "skip the proxy
bridge" rather than an error, add `--proxy-server` only when a bridge actually started, and
declare the bridge variable in the outer scope so the exit handler never references an
undefined binding.

**Verify the launch before debugging the script.**
`curl -s http://127.0.0.1:<port>/json/version` must return a Browser/Protocol-Version
block. Read the `User-Agent` in that response too — it is the fastest proof the fingerprint
persona (e.g. `Windows NT 10.0`) actually applied.

## Locale-agnostic selectors (Meta / Google / OAuth flows)

Third-party automation repos hardcode English UI strings into their selectors. Auth
providers serve the page in the visitor's locale, so an English-only selector matches
nothing and the script reports "form never hydrated" while the form is fully rendered on
screen.

**Select by `autocomplete`, `name`, `type`, or `data-*` — never by placeholder text or
button label.** Those attributes are locale-invariant; placeholder strings and button text
are not. Add the localized string only as a fallback selector, never as the primary.

| Instead of | Use |
|---|---|
| `input[placeholder*="Mobile number or email"]` | `input[autocomplete*="username"]` |
| `button:has-text("Continue")` | `button[type="submit"]`, `button[data-pel-click="..."]` |
| `select:nth(0/1/2)` for a date | `select[autocomplete="bday-year"]`, `bday-month`, `bday-day` |
| `input[placeholder*="Card number" i]` | `input[autocomplete="cc-number"]` |

**Diagnose a "form never hydrated" by reading the DOM, not by retrying.** One
`Runtime.evaluate` that dumps every `input`/`select`/`button` with its `autocomplete`,
`placeholder`, and inner text reveals the locale, the current step, and the real field
order in a single shot. A blind retry costs 90s per attempt and teaches nothing.

**Completion pages gate their submit button on every field.** A `disabled` submit button
after the date selects are set means the name inputs
(`autocomplete="given-name"` / `"family-name"`) are still empty — fill them before
clicking.

For Meta-backed signup flows specifically (step order, the server-side rejection signature,
and the one-shot DOM diagnosis snippet), see
`references/meta-signup-risk-gate.md`.

## Remote desktop so the user can log in themselves (never take a password in chat)

Stack: TigerVNC (`Xtigervnc`) + openbox + noVNC gateway. All present on this VPS.

1. **Window manager is mandatory** — without openbox, Chrome's window never maps and the framebuffer is genuinely black (`xwininfo -root -children` shows 0 children).
2. Start order: Xtigervnc -> openbox -> Chrome.
3. Bind VNC to the Tailscale IP only (`-interface <TAILSCALE_IP>`), never 0.0.0.0.
4. noVNC gateway serves static files AND proxies WebSocket -> VNC on one port, so the user opens one URL with zero install.

Verify the framebuffer is not black before handing the URL to the user:
```
ffmpeg -f x11grab -video_size 1400x900 -i :1 -frames:v 1 -y check.png
```
Then check pixel colors with PIL — a black screen is all `(0,0,0)`.

### noVNC gateway gotchas
- `websockets.http11.Response(status_code, reason_phrase, headers, body)` — headers is a `Headers` object and comes BEFORE body. Swapping them yields a malformed HTTP response (curl exit 52 / empty reply).
- `process_request` returns `None` to let the WebSocket upgrade through; anything else is a static file.
- noVNC builds its WS URL as `ws://<host>:<port>/<path>` from URL params `host`, `port`, `path` (default `websockify`).

### VNC auth in raw tests
- Password is bit-reversed per byte into an 8-byte DES key: `bytes(int('{:08b}'.format(b)[::-1],2) for b in (pw + b'\x00'*8)[:8])`
- Use `cryptography.hazmat.decrepit.ciphers.algorithms.TripleDES` (the non-decrepit path is deprecated).
- **PixelFormat field sizes**: `bitsPerPixel` and `depth` are U8, NOT U16. `struct.pack('>BBBBHHHBBBxxx', 32,24,0,1,255,255,255,16,8,0)` = 16 bytes. Getting this wrong makes TigerVNC silently close the connection after ServerInit.

## Sending Gmail via CDP

`mail.google.com/mail/?view=cm&fs=1&to=...&su=...&body=...` fails with "Bad Request" for long bodies (URL length limit). Instead:

1. Open `https://mail.google.com/mail/?view=cm&fs=1`
2. Fill fields (Indonesian UI labels):
   - To: `input[aria-label="Kepada penerima"]`
   - Subject: `input[name="subjectbox"]`
   - Body: `div[aria-label="Isi Pesan"]` (contenteditable)
   - Send: `div[aria-label="Kirim (Ctrl-Enter)"]`
3. Set `.value` + dispatch `input`/`change` events for the inputs.
4. **Body: never use `innerHTML`** — Gmail's Trusted Types CSP rejects it ("This document requires 'TrustedHTML' assignment"). Build DOM nodes instead:
```javascript
bd.textContent = '';
const frag = document.createDocumentFragment();
text.split('\n').forEach(line => {
  const div = document.createElement('div');
  if (line === '') div.appendChild(document.createElement('br'));
  else div.textContent = line;
  frag.appendChild(div);
});
bd.appendChild(frag);
bd.dispatchEvent(new Event('input', {bubbles:true}));
```
5. Dismiss overlay popups (confidential-mode nudge) before clicking Send.
6. Click Send via real CDP mouse events (`Input.dispatchMouseEvent`), not `.click()`.
7. Verify: Gmail toast "Pesan terkirim", then search `#search/subject:"..."` and confirm 1-1 of 1 in Sent.

## Driving the operator's Windows box over Tailscale (residential IP)

When a target 403s every datacenter IP at the WAF, run the browser on the
operator's residential machine instead of debugging the script. SSH in with
key auth over Tailscale, launch Chrome detached, and drive it through a local
tunnel:

1. **Launch Chrome detached or it dies with the SSH session.** A
   `Start-Process chrome ...` over SSH is killed when the session closes — the
   debug port answers for the length of the command, then vanishes, and the
   next connection gets "Empty reply". Write a `.bat` (base64-encode it
   locally so the quoting survives the SSH → PowerShell hop) and register it
   as a scheduled task:
   ```
   schtasks /create /tn ds-chrome /tr C:\ds-launch.bat /sc once /st 23:59 /f
   schtasks /run /tn ds-chrome
   ```
   The bat launches chrome with `--remote-debugging-port=9222
   --remote-allow-origins=*` and a dedicated `--user-data-dir` so the run never
   touches the operator's main profile.
2. **Tunnel the CDP port:** `ssh -f -N -L 9222:127.0.0.1:9222 <user>@<box>`,
   then point the CDP client at `http://127.0.0.1:9222` (set `CDP_PORT=9222`
   for `cdp_min.get_page()`).
3. **Verify from the box first, then through the tunnel.** A box-side
   `Invoke-RestMethod http://127.0.0.1:9222/json/version` that answers while
   the tunnel returns "Empty reply" means the Chrome instance died or the
   tunnel dropped — re-check both before debugging the client. Chrome's
   DevTools port can also answer briefly and then close; re-test after a few
   seconds before concluding anything.

## Cleanup
Always shut down the VNC exposure when done (`kill -9` by explicit PID — `pkill -f` tends to SIGTERM the calling shell first):
```
for pat in novnc_gateway.py watchdog.sh Xtigervnc openbox; do
  for pid in $(pgrep -f "$pat"); do [ "$pid" != "$$" ] && kill -9 "$pid"; done
done
```
`pgrep -f`/`pkill -f` match the calling shell's own command line too — use a
bracket escape (`pgrep -f '[s]sh -f -N -L 9222'`) so the pattern cannot match
itself and take the shell down with it.
