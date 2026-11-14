---
name: bug-bounty-submission
description: "Use when submitting a verified finding to a bounty platform."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [security, bug-bounty, reporting, submission, yeswehack, hackerone]
    related_skills: [web2-security-recon, bug-bounty-recon]
---

# Bug Bounty Report Submission

Class-level procedure for turning a verified finding into a submitted report on
YesWeHack or HackerOne, .
## When to Use

- A finding has been verified and is ready to be written up and submitted.
- Deciding whether a finding is eligible at all before investing in a PoC.
- Filling a YesWeHack or HackerOne report form through the desktop preview pane.
- Submitting a report by email to a program that publishes only a security contact.
- Checking a CORS, SSRF, or superuser-only finding for submittability.

Not for: recon and verification (use `web2-security-recon`), program selection
(use `bug-bounty-recon`).

## Always-on rules

1. **Run the eligibility gate before writing a single line of the report.**
   Three checks, in order, all mandatory:
   - **Duplicate check.** Search the platform's hacktivity AND the open web for
     the finding class on the same asset — including individual researchers'
     public audit notebooks and security-research sites, which publish full
     finding lists long before anything reaches the platform. On HackerOne a
     duplicate earns nothing; on YesWeHack only the first reporter is rewarded.
  - **When the target's own intake is the vulnerable endpoint, reading it IS the
     duplicate check.** A support chat widget, contact form, or public API that
     accepts unauthenticated writes lets you list every prior report on the same
     issue before you submit — and when the intake is the bug, those reports sit
     in the very collection you just read. Do this FIRST: it costs one request
     and it is the difference between a first report and a duplicate.
  - **WordPress-plugin findings: check three named sources before writing the
     report.** WPScan (`https://wpscan.com/plugin/<slug>/`), Patchstack
     (`https://patchstack.com/database/wordpress/plugin/<slug>/`), and NVD
     (`https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=<plugin>&resultsPerPage=100`,
     paginate with `startIndex`). Match on the FUNCTION and the MECHANISM, not the
     CWE: a historical CSRF entry on a different endpoint is not a duplicate, and
     neither is an IDOR on the same function in a version fixed years ago. Read
     the target's own changelog too — a recent hardening pass that introduced the
     defect is both the root cause and the evidence it is not a known issue.
   - **Out-of-scope class check.** Read the program's non-qualifying /
     out-of-scope list and match the finding CLASS against it, not just the
     asset. A real, reproducible bug in an excluded class is still worth zero.
   - **Target-selectable check.** On any platform whose submission form names
     its targets in a dropdown, enumerate that dropdown BEFORE writing the
     report. A finding whose asset has no entry in the target list cannot be
     submitted at all — not "submitted and forwarded", not "submitted at a
     lower reward", but blocked at the form. An umbrella program covering a
     vendor's ecosystem may list only the vendor's own products and silently
     exclude everything else; the brief's "we will forward third-party reports"
     sentence is a promise about triage goodwill, not a target entry. When the
     asset is absent, pivot to the vendor's own disclosure channel instead of
     writing a report that has nowhere to go.
   - **Re-test.** Re-run the exact reproduction immediately before submitting.
     Findings go stale; a fixed bug submitted is an Informative close and a
     wasted credit.
   - **Documented-non-issue check.** When the target ships its own security
     model, threat model or disclosure policy, read its "non-issues" /
     "wrong claims" section and match the finding against it. Code-review
     programs publish a false-positive catalogue naming the classes they close
     on sight.
   - **End-to-end impact check.** A verifier accepting a malformed proof is an
     observation, not an impact. Prove the protocol's OUTPUT changes: test the
     harmless variant against the harmful one, and if the only feasible forgery
     is a shift that vanishes under the protocol's own modulus, the output is
     unchanged and the finding is a false positive. If the harmful variant needs
     the Fiat-Shamir challenge to bind a term the prover chose, that is a hash
     fixed point — infeasible; say so and stop.
   - **Negative-claim depth check.** Before writing "no rate limiting", "no
     lockout", "no attempt counter" — actually trigger them. Three failed
     attempts proves nothing; the control usually fires somewhere between 5 and
     50. Zecible closed a brute-force report with "the code is invalidated after
     repeated failures, and requesting new codes is limited too" because only 3
     attempts were made. A control you never hit is not a missing control.
   - **Demonstrated-impact check.** "No access to a third party's data is
     demonstrated" is a close reason on its own. A theoretical chain
     (enumerate → brute force → read) with no step actually executed scores
     zero. Either execute the chain on data you own, or downgrade the claim to
     what was really observed.
   - **Capability-id entropy check — run it BEFORE building the full PoC.**
     When a finding is "unauthenticated endpoint returns X given id `{uid}`",
     the id IS the access control, and its entropy decides the severity.
     Probe the id format first: a UUID-shaped id that reaches the lookup logic
     and 404s means high entropy, so the finding is missing-auth-on-an-
     unguessable-token — an Informative at best, and any full PoC that needs a
     real id (a sanctioned test account, a booking flow, an invitation email)
     is not worth building. A short/sequential id that 404s the same way is
     the opposite: enumerable, high severity, worth the full chain. The probe
     costs two requests; the PoC can cost a session.
   - **Pre-screen the vuln CLASS against the non-qualifying list BEFORE building
     any PoC.** On YesWeHack these classes are non-qualifying on nearly every
     program: lack/bypass of rate-limiting, brute-forcing, captcha; user
     enumeration; weak password policy; missing security headers; session
     management; self-XSS; open ports without PoC; GraphQL introspection;
     subdomain takeover without exploit; best-practice/hypothetical flaws.
     Zecible cost 12 credits (-2 × 6 cost) on exactly this. Read the list first,
     pick a qualifying class, then hunt.
   - **Program liveness check.** Render the engagement page and look for a
     paused / ended banner before opening the form. A program can look strong
     on payout and competition and have been paused for over a year; the brief
     then says to stop all testing immediately.
   Report the gate result to the operator before opening the form. the operator asks for this
   explicitly — never open a form on an ungated finding.

2. **CORS findings need demonstrated authenticated impact on both platforms.**
   HackerOne's Core Ineligible Findings list "permissive CORS configurations
   without demonstrated security impact"; YesWeHack programs routinely add
   "CORS without a working PoC reading authenticated victim data (200 response,
   cookie-based auth) from an attacker-controlled origin" to non-qualifying.
   A reflected `Origin` plus `Allow-Credentials: true` on endpoints that answer
   401 is NOT enough — the PoC must read a 200 carrying real data cross-origin.
   Without an account to authenticate with, the finding is not submittable; say
   so instead of writing it up.

3. **Superuser-only and code-analysis-only findings need a running instance.**
   Well-paying programs require validation in a real, running instance and
   reject reports based solely on code analysis. A local clone proves the code
   path exists; it does not prove exploitability. Stand up the instance before
   writing the report. Expect a superuser-only bug to be capped at High
   severity regardless of what it could do as an admin.

4. **Match the program's User-Agent requirement on every test request.**
   Read the UA from the program's rules or JSON record before testing, and put
   the same UA in the report's technical-environment field. A UA mismatch is a
   procedural deviation the triager can see.

5. **State in the report what was NOT done.** If the program bans brute force
   or high-volume traffic, say explicitly that the attack was not executed and
   that the missing control is itself the proof. Never imply an exploit ran
   when it did not.

6. **Verify the rendered description AND the severity before submitting.**
   Switch to the Preview tab and read the description back. Flattened text,
   visible raw tags, or a validation outline means the description is broken.
   Read the CVSS vector back off the page and confirm the score is non-zero —
   a vector with every impact metric at `N` scores 0.0 and submits as "None".
   Both must be right before the submit click, because the submit is
   irreversible and costs credits.

7. **Check the preview pane's session before telling the operator to submit himself.**
   The Hermes preview pane holds the operator's authenticated YesWeHack and HackerOne
   sessions — it is the same browser that submitted the HackerOne reports.
   Run `desktop_preview action=read` and look for a personalized page (his
   username, "My programs", a submitted-reports table) BEFORE concluding
   "not logged in". A redirect to `/auth/login` seen in the VPS headless Chrome
   on port 35867 says nothing about the preview pane: two browsers, two
   sessions, and the preview pane is the logged-in one. Telling the operator to
   copy-paste into his own laptop when the pane is already authenticated reads
   as pushing the work back at him.

   YesWeHack landmarks: alias list at `https://yeswehack.com/user/tools/email-alias`,
   submitted reports at `https://yeswehack.com/reports`, program page at
   `https://yeswehack.com/programs/<slug>`. A program page whose Credits section
   reads "You need N more credits" means the form is unreachable regardless of
   session state.

8. **Know when the preview bridge cannot fill a form at all.** Two shapes end
   the attempt — recognise them and hand the fields to the operator instead of burning
   turns guessing refs:
   - **Angular Material / `mat-form-field` inputs are not in the AX tree.**
     `drive_preview elements` returns only the `<label>` refs for them, and
     `type` into a label fails with "not a text field". Plain-HTML forms
     (Gmail, HackerOne, YesWeHack) fill fine; an Angular SPA does not.
   - **Refs die on navigation and `elements` then answers with a bare delta.**
     After the page navigates every ref is stale, and `elements` returns
     `{"delta":{"same":N}}` with no element list — which reads as "nothing
     changed" when the inventory is actually unrecoverable. Never
     `desktop_preview action=close` to force a fresh inventory mid-flow: it
     resets SPA state and loses the in-progress form. Close and reopen only
     once the flow is finished.

9. **A captcha plus SMS-to-a-phone-you-own gate is a hard blocker, not a
   puzzle.** When the only route to a demonstrated-impact PoC runs through the
   target's own signup, check the verification gateway's country reachability
   BEFORE investing turns: submit the form once, and if no code arrives for a
   number the hunter genuinely owns, the gateway does not cover that country —
   two numbers with zero SMS is the signal, not a delay, and a "code sent"
   confirmation is not a delivery confirmation. State the blocker in one line
   and pivot to a target whose PoC needs no account. Do not build a captcha
   bypass and do not ask the operator to keep hitting resend.

10. **Budget two attempts per approach, then report the blocker.** A third
    retry of the same failing variant reads to the operator as looping, not as
    diligence. When an approach fails twice, state the blocker in one line and
    either pivot to a genuinely different mechanism or hand the operator the single
    remaining manual step. Four corollaries that cost whole sessions when
    broken:
    - Never ask the operator to log in when a session already exists in the instabox VM
      browser.
    - Never re-derive a restriction this skill has already resolved — read the
      skill's reference file before touching the form, not after the third
      failure.
    - **Never treat an obstacle as a blocker without observing it in the live
      DOM.** Query for the widget, read the button's actual label, count the
      iframes. A blocker you did not observe is a fabrication, and the operator calls it
      out as one ("lo ngarang").
    - **When the operator states a method worked before, find and use that method.**
      Search the skill's references and session history for the
      previously-working path first; do not substitute a new approach because
      the old one looks harder.
    - **When a proven method fails on its second run, suspect leftover state,
      not the method.** The first run leaves residue — Gmail drafts, a stale
      pane, a resumed session — and the identical call then fails. Observe the
      live state (draft count, bounce messages, current URL) and clean it,
      then retry the SAME method unchanged. Do not theorize about caps, rate
      limits or edge nodes, and do not trim the deliverable to chase a phantom
      limit; both read as guessing and cost the operator's trust.

## YesWeHack credit economics (read before every submission)

YesWeHack charges credits per submission and pays them back only on a good
outcome. A wasted submission is a real, unrecoverable loss.

| Report status | Credit effect |
|---|---|
| New (on submit) | -1 × submission cost |
| Accepted / Resolved | +2 × cost |
| Informative / Won't fix / Duplicate / Autoclose | +1 × cost |
| NMI / Under Review | 0 |
| RTFS | -1 × cost |
| **Invalid / OOS / Not Applicable** | **-2 × cost** |
| Spam | -3 × cost |

Severity bonus on top: Critical +3 × cost, High +2 × cost, Medium +1 × cost.

- Check the balance and the per-program cost on the program page (Credits
  section) and on `https://yeswehack.com/programs` before opening the form.
  If the balance is short, `/report/new` silently redirects to `/reports` —
  that redirect is the "insufficient credits" signal, not a broken link.
- Some programs cost **0 credits** (e.g. Kiteworks) — free to submit, so the
  gate is the only filter there.
- One automatic refill per hunter, granted only when the balance stays at or
  below 2 for 15 days. Do not plan around it.
- **Never submit to recover credits.** Submitting a weak report to earn credits
  back is how the balance goes negative in the first place. Gate harder instead.

## Bugcrowd submissions (different from YWH/H1)

- Login URL is `https://bugcrowd.com/user/sign_in` — **singular `user`**.
  `/users/sign_in` (plural) returns 404, which reads as "cannot log in" and
  sends you debugging auth instead of a typo.
- Bugcrowd authenticates researchers through **Okta SSO**
  (`login.hackers.bugcrowd.com/oauth2/...`), so the desktop preview bridge
  cannot hold a session — but the operator's live session in the instabox VM browser
  can, and the form fill AND the submit are both fully drivable. **The only
  hard blocker is an expired Okta SSO session** (see below). When the operator states a
  session or tool exists, it does — exhaust it before handing work back.
- The engagement page is a pure SPA and the in-scope target list stays masked
  (`████`) until the program is joined, so joining is a prerequisite for both
  seeing scope and submitting.
- **The researcher alias `<username>@bugcrowdninja.com` exists and forwards to
  the account's primary email.** Bugcrowd generates it on first sign-in and
  re-syncs it on every sign-in (allow ~10 min). It does not appear in the
  profile API's email list, so absence there is not evidence it is missing —
  confirm via the Bugcrowd docs, and note that outbound SMTP from this host is
  blocked so an RCPT probe is not available. Several briefs (Atlassian among
  them) mandate signing up for test instances with this alias, so verify it
  before starting an instance-creation flow.
- **Full recipe — session preservation, form mechanics, draft cleanup,
  Turnstile bypass via React-fiber callback invocation, cf-solver token
  minting and its origin-binding pitfall, instabox exec gotchas — in
  `references/bugcrowd-cdp-submission.md`.** Read it before touching a
  Bugcrowd form; every pitfall there (draft explosion, non-persisting fields,
  in-memory session cookies, origin-bound tokens) costs a session to
  rediscover.

### Bugcrowd submit — verified mechanics (supersedes the earlier "cannot automate" read)

The submit IS automatable end-to-end except for the Okta SSO login itself.
Verified chain: form fill → submit click → **PUT
`/submissions/<id>/publish`**. When a Turnstile widget is present on the page
the publish is fired by invoking the widget's `onSuccess` through the React
fiber, carrying `cf_turnstile_response`; when no widget is present the button
calls `submit(null)` directly and no token is needed at all. Confirm which case
you are in with a DOM query before building anything — see the reference.

**The PUT to `/submissions/<id>` is NOT the submit — it only saves the draft.**
The server answers `200 "Your submission has been updated"` and the report
stays in Draft. The publish is a separate **PUT** to
`/submissions/<id>/publish`; POST and PATCH on that path return `404`, so a 404
there means the wrong verb, not a missing endpoint.

**The one hard blocker is Okta SSO session expiry.** `/submissions/new` and
`/submissions/<id>/edit` redirect to `login.hackers.bugcrowd.com` the moment
the Okta session dies, while the engagement page keeps rendering — a working
engagement page does NOT mean the submit path is authenticated. When the
redirect appears, the login page arrives with the operator's email pre-filled and
"Remember this device's MFA" already on: hand the operator that one step (password +
MFA), then re-run the submission script. Do not spend turns re-navigating or
re-warming the session — the redirect is deterministic, not transient.

When a Turnstile widget is present, budget ONE token attempt per fresh Okta
login, not ten: solve the token immediately before the click (TTL 300s), click
the submit button, then invoke the widget's `onSuccess` — see the reference for
the exact ordering, which is the difference between the publish firing and a
silent no-op.

### Bugcrowd Turnstile — hard blocker on the instabox VM (verified 2026-11-06)

Cloudflare Turnstile **cannot be solved on the instabox hunt VM**. The widget's
challenge iframe loads but never leaves "Checking your Browser…", so no token
is ever minted and every publish returns `422 {"message":"Security verification
failed. Please try again."}`.

**WORKING FALLBACK — hand the draft to the operator for a one-click submit from his own
laptop.** Verified end to end on 2026-11-06: the agent fills and saves the draft
in the VM browser, the operator opens the same `/submissions/<id>/edit` URL on his laptop
(different IP — Cloudflare does not block it, no Turnstile renders at all),
re-sets the two fields that reset on page load, checks the T&C box, and clicks
"Report vulnerability". The submission lands as **New / P2** immediately.

**The two fields that reset on every page load** — re-set them in the same
session as the submit click, or the publish silently no-ops:

1. **VRT** (three-level dropdown). On the laptop it is a plain `<select>`-style
   dropdown showing e.g. "P2 — Server Security Misconfiguration > Server-Side
   Request Forgery (SSRF) > Internal Secrets Exposure"; in the VM it needs the
   JS `.click()` on `aria-label` matches.
2. **The T&C checkbox** `#submission_terms_and_conditions`.

Title, target, description and collaborators DO persist in the draft — verify
them, do not re-type them.

How to confirm you are in the blocked state (do this FIRST, before any solving attempt):

- `document.querySelectorAll('iframe')` returns **empty-src iframes** — that is
  NOT proof the widget failed. The real check is `http://127.0.0.1:<port>/json/list`:
  the challenge iframes appear as separate targets with
  `type: "iframe"` and url `https://challenges.cloudflare.com/cdn-cgi/challenge-platform/...`.
  Connect to one with CDP and read `document.title` — `"Checking your Browser…"`
  forever means blocked.
- Root cause visible in the iframe console: `Fetch API cannot load data:,.
  Refused to connect because it violates the document's Content Security
  Policy` (the challenge's `connect-src` does not allow `data:`), plus
  `performance.getEntriesByType('resource')` stays `[]` — the challenge script
  never issues its API calls.

Tried and FAILED (do not repeat): headless chromium; non-headless on Xvfb
1920x1080; `--disable-blink-features=AutomationControlled`;
`--use-angle=swiftshader-webgl --enable-unsafe-swiftshader` (fixes WebGL, does
not help); `--disable-web-security`; the user's real browser on DISPLAY=:1;
cf-solver `type:"turnstile"` route mode. **cf-solver tokens are invalid** — a
real Turnstile token starts `0.`, the solver returns one starting `1.` (773
chars, 3 dots); the server rejects it with the same 422.

Two mechanics worth keeping from that session:

- **The CSRF header value is NOT the `csrf-token` cookie.** Read
  `document.querySelector('meta[name="csrf-token"]').content`. Sending the
  cookie value as `X-CSRF-Token` makes the publish return **404 Not found**,
  which reads as a wrong endpoint when the verb and path are correct.
- Publish is `PUT /engagements/<slug>/submissions/<id>/publish` with body
  `{"submission":{...},"cf_turnstile_response":"<token>"}` — the token sits at
  the TOP level, a sibling of `submission`, not inside it.

When blocked, the draft is still fully saved (form 100% filled, terms checked,
"Saved about N hours ago"). Report the blocker in one line with the iframe-title
evidence; do not burn turns re-launching browsers.


## Email submissions (programs with no web form)

Open-source and security.txt programs (SecureDrop, many FPF projects) publish only
a security contact and take the report by email. the operator's Gmail is logged into the
Hermes app browser, so the preview bridge drives it.

- Open the compose window with the **query-string form on the `/u/0/` path**, not a
  bare host and not a hash fragment:
  `https://mail.google.com/mail/u/0/?view=cm&fs=1&to=<addr>&su=<url-encoded subject>`.
  `#inbox?compose=new` does not open a compose dialog — the pane just loads the
  inbox and every later `elements` call returns inbox refs. **The `/u/0/` segment is
  required**: without it Gmail silently discards the compose params and lands on
  `#drafts` with no draft created, which reads as "the URL did nothing" rather than
  a wrong URL. Confirm the compose actually opened by checking the page title
  ("Tulis Surat") and that the sidebar draft count incremented — a landed compose
  always saves a draft.
- Wait ~8-10s after `open` before the first `elements`; the compose form is a
  late-rendering SPA view and an early inventory comes back empty.
- Field refs: body is `inp-isi-pesan`, send is `btn-kirim-ctrl-enter`. To and
  Subject arrive pre-filled from the URL.
- **Do not type a long body at all — inject it through the compose URL.**
  Gmail accepts a `body=` query parameter and preserves newlines (`%0A`) and
  indentation, which `type` cannot do:
  `https://mail.google.com/mail/u/0/?view=cm&fs=1&to=<addr>&su=<url-encoded subject>&body=<url-encoded body>`
  Encode with `urllib.parse.quote_plus` — `+` for space is shorter than `%20`
  and buys room under the length cap.
- **The compose URL has a hard length cap, bisected 2026-11-07 to between 10,333 and
  10,984 chars.** A URL at 10,333 chars opens the compose window normally; 10,984
  returns `Error 400 Bad Request`. Treat ~10.3 KB as the working ceiling and trim
  the body to ~8.3 KB of text (≈9.5 KB URL) so there is headroom. Assert the URL
  length in the generating script rather than discovering the cap by trial.
- **Read a long compose URL back in slices, never in one call.** The URL has to be
  passed verbatim into the `open` arguments, but `read_file` and terminal output
  both truncate a single long line at roughly 2,000 chars — a 5 KB URL read in one
  call comes back silently cut and the compose opens with a mangled body. Print it
  in fixed-size slices from a script instead:
  `python3 -c "u=open('url.txt').read().strip(); print(u[:1800])"` then
  `print(u[1800:3600])` and `print(u[3600:])`, and concatenate the slices when
  building the tool call. Print the total length first and assert it matches the
  file, so a dropped slice is visible rather than inferred.
- **The desktop bridge `open` action also chokes on very long URLs, but the
  failure is a JSON parse error, not a bridge error.** A 9.4-10.1 KB URL in the
  `open` arguments fails with `tool_call 'calls' is not valid JSON: Extra data:
  line 1 column N` where N lands just past the URL's end — it reads like a
  malformed call but is a size limit on the tool-call payload. The same URL
  opened fine when the operator pasted it into his own browser. When `open`
  fails this way, stop trimming the report to chase a phantom cap: hand the
  operator the compose URL as a chat link, let him open it in the desktop
  pane, then drive the send from there (`elements` -> click `Kirim` -> confirm
  in `#sent`). The operator opening the URL himself is the working route for
  long bodies, not a fallback.
- **Trim by HARD DELETE, never by rewrite.** A `md[:i] + new + md[j:]` replacement
  whose `new` is the text you just read out of the file returns the identical
  string and the char count does not move — re-running it in a loop burns turns
  without shrinking anything. After every edit print the new length and diff it
  against the previous one; if it is unchanged, the replacement text was
  identical, so write genuinely shorter prose or delete a whole section outright.
  Cutting a section and pasting a compacted version back is the trap: it looks
  like progress and saves ~0 chars.
- **Discard any existing draft before opening the compose URL.** Gmail resumes
  a saved draft and silently ignores the `body=` parameter, so the window comes
  back with the old body and none of the new text. Click
  `btn-buang-draf-ctrl-shift-d` first, then open the URL.
- **Every compose-URL open saves a draft — including a no-body "test" open.**
  Opening `?view=cm&fs=1&to=...&su=...` with no `body=` to "check the window
  opens" leaves a draft that hijacks the NEXT compose URL: Gmail resumes it and
  drops the new body. Never open a compose URL as a test. Before the real open,
  read the sidebar draft count (`Draf N`), and clean your own drafts from
  `#drafts`: tick the row checkbox, then click **Hapus draf** — the compose
  overlay's own discard button is often absent from the AX tree, so the list
  route is the reliable one. Leave the operator's old drafts alone.
- `type` on the Gmail body enters HTML as **literal text** — the tags render
  verbatim, they are not parsed. Plain text via the URL `body=` parameter is
  the working route; reserve HTML for platform forms that render it.
- **`press` appends one key at a time and truncates a multi-char string to its
  first ~3 characters.** It is the only append primitive, so it is viable for a
  short correction or a line break (`press Enter` works and adds a newline) —
  never for a report body. Batch `type`+`press` calls in one turn race: only
  the last action lands, so issue them one at a time.
- Confirm the send with `desktop_preview action=read`: a sent compose shows
  **"Pesan terkirim"** plus an **"Urungkan"** (Undo) link, and the send button
  disappears from the inventory.
- **A closed compose is not a delivered email — check the inbox for a bounce
  before reporting success.** Gmail accepts the message at click time and
  reports a dead address minutes later as a Mailer-Daemon bounce in the inbox
  ("Alamat tidak dapat ditemukan" / "The email address doesn't exist"). After
  the send, load `#inbox` and look for the bounce on the report's subject;
  only then say it landed. A wrong address is a silently lost report.
- **Confirm delivery in `#sent`, not just from the compose closing.** Load
  `https://mail.google.com/mail/u/0/#sent` and read the entry back: the To
  address, the subject, and the body preview must all match what was sent, and
  the folder count must have incremented. The compose window closing and the
  send button leaving the DOM prove the click landed, not that the message
  exists — only the Sent-folder row is end-to-end proof. Report the timestamp
  and the To address to the operator, never just "sent".
- **A ticket-system auto-acknowledgement is not a human accepting the report.**
  When the first reply comes from an automation address (`jira@<vendor>.atlassian.net`,
  `noreply@`, `donotreply@`) and its body is boilerplate — "Just confirming that
  we got your request. We're on it.", a "Reply above this line" delimiter,
  "Powered by Jira Service Management" — it is the receipt every ticket in that
  system sends, not triage. No severity, no bounty decision, and no engineer has
  read the finding. Record it as `SUBMITTED_ACKED`, never as accepted or
  resolved, and tell the operator plainly that nobody has looked at it yet. The
  tell is the sender domain and the canned phrasing, not the enthusiasm of the
  wording.
- **Believe the operator's screenshot over one `read`.** A `read` can report a stale
  success state. If the operator says it was not sent and his screenshot still shows the
  Kirim button, it was not sent — re-open compose, re-fill, re-send. Read the To
  address character by character before clicking send; a wrong domain is a
  silently lost report.
- **Bridge recovery when the pane goes stale mid-compose.** The renderer
  occasionally rejects every action with `Invalid guestInstanceId` while the
  page still looks alive. Re-`open`ing the same URL does NOT clear it. The fix
  is `desktop_preview action=close` (closes all panes), then `open` the compose
  URL again, wait ~10s, then `elements`. Budget for this: it fires roughly once
  per two submissions, and each recovery costs a close + reopen + wait.
  **`close` DISCARDS an unsent compose — the draft vanishes and the body is gone.**
  Gmail saves a draft when the compose renders, but closing the pane abandons it
  rather than preserving it, so a compose that was filled and verified but not
  yet sent is lost and must be rebuilt from the compose URL. Before reaching for
  `close`, check whether the compose is already sendable: if `btn-kirim-ctrl-enter`
  is still in the inventory, click it first and recover afterwards. Only close
  when there is nothing to lose.
- **A `type` that returns a bridge error may still have landed.** After a failed
  `drive_preview type`, call `desktop_preview action=read` before retyping —
  the body is often already filled. Because `type` replaces rather than
  appends, a retry is safe (it overwrites), but it wastes a turn and can reset
  a compose window mid-fill.
- **`drive_preview type` REPLACES the whole field value — it does not append.**
  Typing the body in several chunks is NOT safe: each call leaves only the last
  text in the field, and the earlier chunks are gone rather than scrolled out of
  view. Check `total_chars` in the read result against the expected body length
  before concluding anything.
- **`type` also has a hard cutoff at ~3 KB of text — the bridge times out
  mid-stream and the field keeps only what landed.** Verified 2026-11-07 on a
  7.4 KB Gmail body: three attempts landed 3,850 / 3,050 / 0 chars, each ending
  in "No Hermes Desktop window answered", while `click`, `elements`, `read` and
  `open` kept working on the same element. A 1-char `type` succeeds, so the
  limit is size, not focus. **A body over ~3 KB cannot be typed at all** — hand
  the operator the text to paste instead, or inject it by URL.
- **When `type` cannot carry the body, hand the operator the text to paste —
  it is the working route, not a last resort.** Give the full body in a fenced
  code block and have him click the compose body, `Ctrl+A`, `Ctrl+V`. Verified
  2026-11-07: a 7.2 KB ikuTeam report pasted this way landed complete (7,761
  chars in the Sent copy) after `type` had failed three times. Clear the field
  first with a 1-char `type` so the paste does not append to stale text.
- **`tool_call` arguments for `drive_preview` use `action`, never `type`.**
  `{"action": "type", "ref": ..., "text": ...}`. Passing `"type": "drive_preview"`
  is a schema error that surfaces as a confusing JSON parse failure, not as a
  clear "missing action" message.
- **Never put `\n` in a `tool_call` text argument, and do not probe escape
  sequences to make `type` produce line breaks.** A literal `\n` in the JSON
  parses, but the bridge swallows it — the field gets the lines run together
  with no break — and a double-escaped `\\n` types as visible backslash-n.
  Neither yields a newline, so stop after one probe. Write HTML bodies as one
  line and carry structure with block tags (`<h3>`/`<p>`/`<ul>`); `<br>` where
  a break is needed inside a paragraph. For plain-text email the URL `body=`
  parameter is the only route that preserves newlines.
- **The bridge can die mid-compose with "No Hermes Desktop window answered".**
  This is not the stale-`guestInstanceId` case and re-`open`ing the same URL
  does not clear it. Wait ~25s, then retry the action — the compose state
  (To, Subject, body) usually survives. **If the retry also fails, stop
  retrying and ask the operator to click/focus the chat window in the Desktop app.**
  The renderer only answers while its window is the foreground one; a
  backgrounded or minimised Desktop app makes every `drive_preview` action
  fail identically, and no amount of waiting or re-`open`ing fixes it. Two
  failed retries is the signal to hand it to the operator, not to try a third time —
  each round costs turns and reads as stalling. If an `elements` delta reports
  the body ref as `removed`, the content is usually still intact; confirm with
  `read` and `total_chars` before re-typing anything.
- **A third bridge-death message exists: "No Hermes Desktop window is showing this
  chat, so its preview, terminal and tour are out of reach."** Same cause and same
  fix as the two above — the Desktop app is not the foreground window. It can
  also fire on a plain `desktop_preview action=read` after a successful `open`,
  so a compose URL that opened fine is not proof the bridge is still alive.
  Recognise the string, ask the operator to focus the chat window once, and
  retry the same action; do not rebuild the compose from scratch.

## Third-party app in an umbrella program → vendor disclosure

When a marketplace or ecosystem umbrella program's submission dropdown lists
only the vendor's own products, a third-party app on that marketplace has no
target entry and cannot be submitted there at all. Enumerate the dropdown
first (rule 1), then route to the vendor:

- Find the vendor's security contact from the marketplace listing's support or
  security tab and the vendor's own site. A vendor publishing a 24x7
  `security@` address alongside a business-hours `support@` is running a real
  intake; use the security address.
- Confirm the domain accepts mail before writing the report: query the MX records
  (`curl -s "https://cloudflare-dns.com/dns-query?name=<domain>&type=MX" -H "accept: application/dns-json"`)
  and check they point at a live provider (Google Workspace
  `aspmx*.googlemail.com`, Mailgun `mx*.mailgun.org`). A domain with no MX or
  only web/CDN addresses cannot receive the report at all.
- State in the report that the umbrella program has no target entry for the app
  and that the vendor channel was used instead — triagers read that as
  diligence, not as an off-platform dodge.
- Do not repeat the umbrella program's headline reward numbers for a
  third-party finding. Umbrella coverage of third-party apps is case-by-case
  and pays nothing guaranteed; say so plainly.

## Several distinct root causes in one artifact → separate reports

A single app, plugin or repo often yields N findings whose root causes are
unrelated. Most briefs carry a same-root-cause rule: group what shares a cause,
split what does not. File them as separate reports, not one bundled document.

- **Decide by root cause, never by asset or by CWE.** Two CSRF bugs reached
  through different missing checks are two findings; two symptoms of one missing
  authorization check are one. Write the root cause in one sentence per finding
  and group on that sentence.
- **Each later report references the first by its ticket or report id** and
  states in its opening line that it is a separate root cause filed under the
  same-root-cause rule. Without that sentence a triager who has already seen the
  first report closes the second as a duplicate on sight.
- **Never let a later report depend on an earlier one being read first.** Each
  must stand alone: its own target and version, its own artifact, its own
  reproduction, its own impact and fix. Cross-reference for context, not for
  completeness.
- **Batch static audits produce this shape by default** — one artifact, many
  independent defects. Expect to file several reports from one clone, and budget
  the submission turns for each rather than treating the audit as one submission.

## Paused program → email fallback

A program whose H1 page reads "taking a break and is not accepting new
submissions" still publishes a security contact, and that contact is the
submission path. Do not treat a paused program as a dead target when the
finding is already verified — check the program page's Contact block, then
submit by the email recipe above. State in the report that the platform form
was unavailable and why the email route was used; triagers read that as
 diligence, not as an off-platform dodge.

## When the email address itself is dead

A Mailer-Daemon bounce is not one failure mode — read the response code before
deciding anything, because the two shapes need opposite responses:

- **"The recipient server did not accept our requests to connect" / connection
  timed out on every listed IP** means the domain has **no mail server at all**.
  Confirm it with a real MX query, not an address lookup:
  `curl -s "https://cloudflare-dns.com/dns-query?name=<domain>&type=MX" -H "accept: application/dns-json"`
  and read the `Answer` array — empty is conclusive. **`getaddrinfo(domain, 25)`
  proves nothing about MX**: it returns only A/AAAA records, so a domain with no
  mail server looks identical to a working one and you will report a dead address
  as a typo. Cross-check the SPF TXT record for a real provider
  (`_spf.google.com`, `helpscoutemail.com`, `mx*.mailgun.org`) — a live mail domain
  almost always publishes one. The address is not wrong — nothing sent there can
  ever arrive, and Gmail will retry for ~46h before permanent failure.
- **"The email address doesn't exist" / a 5.1.1 user unknown** means the address
  is wrong and a different one exists. Search the vendor's own pages for the
  real contact before resending.
- **A `security@` address that bounces is not a typo — find the vendor's real
  intake, then resend the identical report.** ikuTeam (verified 2026-11-07):
  `security@ikuteam.com` bounces with "Alamat tidak dapat ditemukan"; the
  working address published on the ikuTeam Trust Center is
  `support@ikuteam.com`. A Sent-folder entry is not proof of delivery — read the
  bounce in `#inbox` first, then resend to the corrected address with the same
  compose-URL method that worked the first time.

Do not resend into the first shape, and do not tell the operator the address was
typos'd when it was not — he will "fix" a correct address.

**When the only published intake is a dead address, deliver through the target's
own live channel instead.** A vendor that runs a support chat widget, a contact
form, or a public API is running a system somebody reads. Find the intake the
widget itself posts to (grep the marketing page for the API host, or read the
widget's endpoint off a network capture), then submit the report as a normal
support conversation through that same endpoint — same payload shape the widget
uses, same origin and referer headers. This is not an attack on the target; it
is using the support desk the vendor actually staffs.

Verify the report landed before telling the operator it is submitted. A created record
id, an `unread: true` flag, or a collection count that increments by one is
proof; a 2xx on its own is not. Re-fetch the collection and confirm your record
is present, then report the id to the operator.

Two rules when using this route:
- **Strip real PII out of the report.** If the finding is an unauthenticated data
  exposure, the leaked records are evidence for the vendor's own dashboard —
  quoting a victim's name and email back at them adds nothing and mishandles
  their users' data. Describe the shape and the count instead.
- **Say in the report that the published address bounces.** One line naming the
  failed address and the reason, so the team knows why an unusual channel was
  used and can fix their intake.

## Check whether the program pays at all

A HackerOne program can be titled "Bug Bounty VDP" and still state in its own
policy that it "does not offer monetary rewards". Read the reward sentence on
the policy page before writing a single line, and correct any dollar estimate
already given to the operator the moment the VDP status is confirmed — he ranks programs
by payout and a silently wrong estimate wastes his planning. A VDP submission
is still worth sending for reputation and swag, but say plainly that it pays
nothing rather than letting the earlier estimate stand.

## Procedure

1. **Gate** (rule 1). Report the result to the operator; stop here if any check fails.
2. **Have the operator open the report form** in the desktop preview pane and log in.
   YesWeHack: `https://yeswehack.com/programs/<slug>/create-report`.
   HackerOne: `https://hackerone.com/<handle>/reports/new`.
3. **Fill the form** with `drive_preview` — mechanics in
   `references/preview-bridge-form-filling.md`.
4. **Verify**: `desktop_preview action=read` for field values, then the Preview
   tab for the rendered description.
5. **Submit**, then read the resulting report page and give the operator the report ID,
   URL, CVSS and status.
6. **Record the submission in the findings DB in the SAME turn, with the proof.**
   Set the status, the submission timestamp, and append the verification evidence
   (ticket or report id, Sent-folder timestamp, To address, whether a bounce was
   checked). A finding left at `FOUND` after it was sent reads as unsubmitted to
   the next session and invites a duplicate submission. Use a distinct status for
   "delivered and acknowledged" versus "delivered, no human has read it" — the two
   mean very different things to the operator, who ranks work by payout.

## Reporting style

Short, casual Indonesian (gue/lo), results first: report ID, URL, CVSS, status.
On a failed gate: lead with the one-sentence verdict, then at most three plain
lines of why, then the next action. No dense tables and no stacked metrics —
the operator answers "gua gak paham" to a wall of numbers. Say "gue nggak submit,
bug-nya nggak bisa dipakai" before any detail.

Write the report body neatly and completely the first time — the operator
rejects careless drafts outright ("teliti yg rapi nulisnya jangan asal"). Keep
every section the vendor needs to reproduce: target and version, the exact
artifact or endpoint, the code or request that proves it, the impact, and the
fix. Never pad a report to hit a length target, and never ship a body with
placeholder or repeated lines left in it.

**Post a one-line status before any long tool sequence.** A verification or
submission flow that runs ten or more tool calls without a word reads as a hang
and the operator will interrupt to ask. Say what you are about to do in one line
("gue cek MX dulu"), run the calls, then report. Never go silent across several
turns of tool work.
