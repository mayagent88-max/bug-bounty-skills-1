# Filling a bounty report form via the desktop preview bridge

Validated end-to-end on a YesWeHack submission. The preview pane renders the
platform page inside the Hermes desktop app; `drive_preview` drives it.

## Tool contract

- `desktop_preview action=read` returns the page's visible text — labels and
  selected dropdown values, but NOT the contents of text inputs. Use it to
  confirm selections and to read a rendered description.
- `drive_preview action=elements` returns a DELTA after the first call, and
  element refs rebind on most actions. Prefer stable CSS selectors for anything
  you touch more than once (`#report-submit-button`, `#AV-N-label`).
- **`elements` only inventories what is VISIBLE in the viewport.** A section
  scrolled out of view — the CVSS calculator on a long HackerOne form is the
  usual case — comes back as `{"delta": {"same": N}}` with no refs at all, and
  every selector guess then fails with "No element matches". Do not burn calls
  guessing selectors: ask the operator to scroll to that section, then re-call
  `elements` to get the refs.
- `drive_preview action=type` **replaces the whole field value** and **strips
  newlines**. It is not an append — typing twice leaves only the second text.
- **A label ref is not an input ref.** Angular/Material forms expose their
  `<input mat-input>` to the AX tree only sometimes. When `elements` returns
  labels (`el-email`, `el-choose-a-new-password`) but no `inp-*` for those
  fields, the inputs are not reachable — `type` on a label fails with "not a
  text field". Do not burn calls guessing `inp-email-1` style refs: the suffix
  is invented by the inventory, and a wrong guess is indistinguishable from a
  dead ref. Hand that one field to the operator and keep driving the rest.
- **`elements` cannot be re-polled for a full inventory.** After the first full
  call it answers `{"delta": {"same": N}}` for as long as the page is unchanged,
  so refs lost to an in-page state change (a dropdown opening, a section
  collapsing) are gone until the page navigates. When you need the full
  inventory back without losing your place, the only reset is
  `desktop_preview action=close` then `action=open url=<url>` — but that
  collapses any expanded SPA section (a registration form that was open comes
  back as just its REGISTER / SIGN IN button), so budget one extra click on the
  expander afterwards. Prefer keeping the pane alive across a flow over
  closing it to chase refs.

## Dropdowns

Open a select by its placeholder, then click the option ref:

    drive_preview click selector='[placeholder="Select a bug type"]'
    drive_preview click ref='opt-brute-force-brute-force'

The bug-type list is long; the search input inside the open dropdown filters it.
Scope lists are hostnames — pick the exact in-scope asset from the program's own
list rather than typing a hostname.

## Multi-line description

Because `type` strips `\n`, markdown structure is lost and the report renders as
one blob. Write the description as **HTML** — both the YesWeHack and the HackerOne renderers pass it
through:

    <h2>Summary</h2><p>...</p><pre><code>...</code></pre><ul><li>...</li></ul>

Escape inside code blocks: `<` -> `&lt;`, `>` -> `&gt;`, `&` -> `&amp;`.

## CVSS

Click the metric buttons, then read the computed vector and score back from the
page before submitting.

- **YesWeHack** uses stable CSS selectors: `#AV-N-label`, `#AC-L-label`,
  `#PR-N-label`, `#UI-N-label`, `#S-U-label`, `#C-H-label`, `#I-N-label`,
  `#A-N-label`.
- **HackerOne** exposes them as refs only — `btn-network-1` (Attack Vector),
  `btn-low-5` (Attack Complexity), `btn-none-5` (Privileges Required),
  `btn-none-6` (User Interaction), `btn-unchanged-1` (Scope), `btn-none-7`
  (Confidentiality), `btn-none-8` (Integrity), `btn-none-9` / `btn-low-9` /
  `btn-high-9` (Availability). The suffix number differs per metric — read the
  labels off the inventory, never guess a suffix.

Severity is mandatory on HackerOne: a vector with every impact metric at `N`
scores 0.0 and submits as "None", so set at least one impact metric. The table
under the vector (Asset Name / Confidentiality / Integrity / Availability, with
values like Medium/Medium/Medium) is the asset's **severity CAP**, not a minimum
requirement — a Low impact on a Medium-capped asset is fine.

## IPs used

Click the program's "Get my IP" button, then correct it if the detected address
is not the one the testing actually came from — the field must name the IP the
requests were sent from.

## When the bridge dies

Three distinct failures, three different responses:

- **`No Hermes Desktop window is showing this chat`** — the app lost track of the
  window. Ask the operator to click the chat window so it is focused, then retry once.
- **`Invalid guestInstanceId: N`** — the pane's guest view is gone; `read` and
  `drive_preview` both refuse. Recover by closing and re-opening the pane:
  `desktop_preview action=close` (closes all), then `action=open url=<url>`, wait
  ~8-10s, then `elements`. Refs from before are dead.
- **`No Hermes Desktop window answered the preview action request`** — transient.
  Wait 10s and retry the same action; it usually lands on the second attempt.

Do not retry unchanged in a loop for any of them — each needs a specific
response, not another identical attempt. `desktop_preview action=read` usually
still answers while `drive_preview` is refused, so state can still be checked.

**A `type` that returns a bridge error may still have succeeded.** Check the field
with `action=read` before retrying: the element ref can vanish from the
`elements` inventory while the content is present, so the inventory is not a
content oracle. Re-typing is safe (`type` replaces, it does not append) but it
wastes a turn and can reset a compose window mid-fill.

## Recovering a dead or reloaded pane

If the bridge drops hard — `drive_preview` times out repeatedly, or
`desktop_preview action=read` answers "no page is loaded" — re-open the pane
with `desktop_preview action=open url=<form url>`. A plain reload re-renders the
form **with the previously filled fields intact** (asset, weakness, title,
description and impact all survive), so this is a safe recovery, not a reset.
Re-run `elements` afterwards: refs from before the reload are dead.

**A failed submit RESETS the form — a reload does not.** These are different
events and must not be treated as the same recovery. After clicking Submit
Report, if the page still shows the form, the submission did not go through and
the weakness/asset selection has been dropped along with the description and
impact textareas. Re-open the form URL, re-select asset AND weakness, re-fill
title/description/impact, then submit again. Detect the reset by checking
whether the weakness section still shows a "Currently selected" line and whether
the description textarea is still in the `elements` inventory — both vanish on
a reset.

## Platform form vs target-site SPA — reload-safety differs

The reload-is-safe rule above was validated on HackerOne and YesWeHack report
forms, which re-render server-side. It does **not** transfer to a target site's
own Angular SPA (a booking or registration flow on the bounty target itself):

- A `close` + `open` there collapses the flow to its entry button (a
  registration form comes back as just REGISTER / SIGN IN), and any in-page
  selection made through the UI is lost even when the surrounding summary
  survives. Budget one click on the expander, and redo the selections.
- The target's flow usually also carries gates the platform form does not — a
  CAPTCHA and an SMS code to a phone the hunter owns. Those are not bridge
  problems and cannot be driven from here; see the hard-blocker rule in
  SKILL.md and hand that step to the operator rather than attempting it.
- Because of both, drive a target-site flow in ONE uninterrupted pass: have the
  pane already open on the right URL, click through the steps back to back, and
  never close the pane to chase a ref mid-flow.
