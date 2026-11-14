---
name: appsec-triage
description: "Appsec coverage checklist for a pentest-team engagement — the surface-by-surface list an operator works through to take a target from claimed to covered, and the list the lead cites as the coverage bar. WSTG/WAHH-derived: recon, authentication, session, access control (IDOR/BOLA/BFLA/mass-assignment), input validation (SQLi/XSS/SSTI/XXE/traversal/command-injection), file upload, business logic, API (REST/GraphQL/OAuth/JWT), request smuggling, and proxy/backend parser differentials (path confusion). Load it when planning coverage or working a web/API surface."
---

# AppSec Triage — the coverage checklist

This is the list that decides when a surface is **covered** on the board. An operator claims a target, works the relevant sections, captures evidence and files findings as it goes, then marks the surface covered with a coverage note citing which sections were run. The lead cites the sections that apply to each surface as the coverage bar in Decisions. "Covered" means the checklist was run and the result recorded — findings filed, or an explicit "tested, nothing found" naming what was tried — not "looked tested".

**Enumerate every code path before you call a class clean.** A class is *covered clean* only when every distinct handler/backend that processes that input has been enumerated and tested — not when the first handler you found is defended. A robust defense on one code path says nothing about a sibling path: an Image field validated by GD vs a File field validated by extension-allowlist only; a web-route access check vs the REST/GraphQL access check for the same object; a user-facing form vs the framework's own AJAX/render pipeline. This is the exact seam where a real bug survives a heavily-tested surface — so before you write "nothing found," ask *what other code path handles this same input?*, name the paths you enumerated (not just the payloads you tried), and if one is untested it goes back on the board.

## Under the engagement protocol

- **Claim the target before you probe** (§Claiming). Coordinate load on a shared host — don't fuzz an endpoint another operator is mid-testing.
- **Stay on the allowlist.** Every item here runs against an in-scope target only. A check that would reach out of scope (an SSRF that leaves the app, an open-redirect to a third party) is proven benignly and reported as reachability — never crossed.
- **Log as you go** to `evidence-ledger.csv`; **file findings** into `FINDINGS.md` in the `appsec-reporting` format the moment you confirm one.
- **Do no harm.** Prefer the least-invasive proof; no stress/DoS to "confirm" a rate-limit gap; a marker record, not a dump.
- Load the deeper per-class skill when a section turns up something worth pursuing (`web-sqli`, etc.).
- **If the ROE grants source access (grey/white-box), run `appsec-code-review` alongside this sweep** — the two correlate: a static sink it finds becomes a targeted probe for the checklist item below (and the dynamic operator confirms it live), and a black-box result here becomes a targeted read of the code that causes it. The strongest findings carry both.

---

## Reconnaissance and mapping

- [ ] Map visible content by browsing the app thoroughly; note every data-entry point.
- [ ] Discover hidden/default content (directory & file brute-force, sensibly rate-limited).
- [ ] Identify technologies (Wappalyzer-style) and research known vulns for that stack.
- [ ] Capture API contracts (OpenAPI/Swagger/GraphQL) and diff against observed traffic.
- [ ] Enumerate all JavaScript files for later analysis (secrets, endpoints, DOM sinks).
- [ ] Identify WAF/CDN/gateway (headers, cookies, block pages) and cache behavior.
- [ ] Test for debug parameters and verbose error surfaces.
- [ ] Confirm scope of subdomains/hosts — and stop at the allowlist edge (report, don't cross).
- [ ] **Seed content on an empty target before testing depends on it.** A content-empty app (zero user objects, one or two accounts) hollows out access-control (no objects to run an IDOR/BOLA battery against) and injection (no stored sinks to reach). This is a lead-assigned precondition, not a mid-test discovery: one operator seeds minimal marker content — known marker strings, comments enabled, one object per relevant owner/identity — and broadcasts the object IDs *before* access-control or injection testing begins.

## Authentication

- [ ] Password quality rules (length, complexity, common-password checks; paste disabled?).
- [ ] Username enumeration (response time, error text, status codes; recovery flow).
- [ ] Guessing resilience — rate limiting and lockout (probe presence, don't brute at volume).
- [ ] Account recovery — weak questions, host-header injection in reset mail, token in Referer, predictable/unvalidated tokens.
- [ ] "Remember me" token entropy, expiry, attributes.
- [ ] Username uniqueness/canonicalization (`admin` vs `Admin`, whitespace trimming).
- [ ] Fail-open conditions; unsafe credential distribution.
- [ ] Multi-stage / MFA — enrollment skip, verification manipulation, code brute-force, easy disable, parameter pollution.
- [ ] OAuth flows → §API. JWT → §API. API-key leakage (source, client JS, mobile app) and misuse (URL/header/cookie).
- [ ] Passkeys/WebAuthn including recovery/fallback paths.
- [ ] **Attack the auth wall.** A 401/403 on an interesting endpoint is a *located gate*, not a closed surface: before recording it gated, re-request the privileged ones (admin, user-management, server config) through the filter-bypass ladder (§Parser differentials) — the app's own auth filter and dispatcher can normalize a path differently with no proxy in front. A gate is "gated" only after it survives the ladder.

## Session handling

- [ ] Token meaning and predictability; insecure transmission (Secure flag, over-HTTP).
- [ ] Token disclosure in logs / URL params; token-to-session mapping (reuse).
- [ ] Session termination — logout fully invalidates? rotation on login/logout/privilege change? timeout enforced server-side?
- [ ] Session fixation — token retained across the auth boundary? can one be forced on a user?
- [ ] CSRF — anti-CSRF token presence/validation, SameSite attribute, Origin/Referer checks; try removing the token, switching method, changing Content-Type; login CSRF; OAuth `state` integrity.
- [ ] Cookie scope — Domain/Path too broad, HttpOnly missing, partitioning/CHIPS in embedded contexts.

## Access control (IDOR / BOLA / BFLA / mass assignment)

- [ ] Map access-control requirements; create an account per role.
- [ ] Horizontal — can User A reach User B's data at the same privilege?
- [ ] Vertical — can a low-priv user reach high-priv resources/functions?
- [ ] Object references — IDs in URL/body/cookie/header; increment numeric IDs, swap UUIDs, decode/modify encoded IDs, add a missing `user_id`, wrap `id:1` → `id:[1]` / `id:{id:1}`, parameter pollution `id=me&id=victim`, `/resource/1.json` type-switch, method-switch GET→PUT/DELETE.
- [ ] BOPLA / mass assignment — can read-only or response-only properties be set via the request? JSON Patch/Merge to sneak forbidden fields?
- [ ] BFLA — admin/privileged endpoints reachable directly (`/admin`), different methods on an endpoint (a guarded `GET` may have an unguarded `POST`/`PATCH`/`DELETE`), older API versions (`/v1/` vs `/v3/`).
- [ ] **Enumerate the privileged surface actively.** A **shadow** route — an admin write no client code calls — is absent from the JS bundle/HAR by definition, so a client-derived map never shows it. Verb-fuzz the `/admin/*` prefixes you've found for siblings; authorization is per-endpoint, so a check on `/admin/users` says nothing about `/admin/accounts/:id/adjust`. A privileged prefix is not `covered` until its routes are enumerated (path and verb).
- [ ] Prove cross-tenant breaks against a planted marker or a second test tenant, not real customer data.
- [ ] A confirmed escalation (priv-esc, role flip, account takeover) is a **new surface**, not just an impact — enumerate what it now reaches and put it on the board (protocol §Findings).

## Input validation

- [ ] Fuzz all parameters; choose targeted payload lists; watch for anomalies.
- [ ] SQL injection — error-based, blind, time-based, OOB (→ `web-sqli`).
- [ ] Reflected/stored/DOM XSS — reflected params, stored sinks (comments, profiles, reviews), blind XSS to admin/log viewers via a callback listener.
- [ ] SSTI — inject `{{7*7}}` / `${7*7}` / `<%= %>`, fingerprint the engine, escalate carefully (read before RCE; RCE only with explicit go).
- [ ] Command injection — params, headers, body, filenames (marker callback, not a destructive command).
- [ ] Path traversal / LFI — file params (`?file=`, `?template=`), encodings, PHP wrappers; escalate to RCE only within scope and rules.
- [ ] XXE — XML inputs and file uploads (SVG/DOCX/SOAP); XML accepted on JSON endpoints? OOB exfil to a benign in-scope callback only.
- [ ] Header/CRLF injection, open redirect, SMTP/LDAP/XPath/NoSQL injection where the stack fits.
- [ ] **Test the framework, not just the forms.** On a stock CMS/framework with little custom code, the application-layer vectors (XSS/SQLi/SSTI) are usually framework-defended — and the real injection surface is the framework's *own infrastructure*: its render pipeline, AJAX/callback plumbing (e.g. Drupal `_wrapper_format=drupal_ajax` + `element_parents` render-array injection → Drupalgeddon2 RCE), serialization/HAL, and internal routing. These are not visible parameters on any form; reach them by driving the framework's internal mechanisms, and don't declare injection clean until you have.

## File upload

- [ ] Enumerate every upload; test executable extensions and alternates (`.phtml`, `file.php.jpg`, trailing dot, `::$DATA`).
- [ ] Content-Type spoof; magic-byte forgery (`GIF89a;` prefix); polyglots.
- [ ] Path traversal / injection in the filename; archive Zip-Slip / symlinks.
- [ ] Post-upload processing chains (thumbnailers, OCR, AV, image libs — ImageTragick/ExifTool) for RCE/SSRF; MIME sniffing vs Content-Type.
- [ ] Race conditions during upload/validation; bypass client-side validation via the proxy.

## Business logic

- [ ] Identify the logic surface — payments, account changes, multi-stage flows get extra attention.
- [ ] Client-trusted data / client-side-only validation.
- [ ] Multi-stage process flaws; incomplete-input handling; trust-boundary confusion.
- [ ] Transaction logic — race conditions/TOCTOU, idempotency-key replay, double-spend (prove with a marker transaction, reverse it, respect no-real-data).

## API testing

- [ ] Identify types (REST/SOAP/GraphQL); SOAP WSDL discovery.
- [ ] Info disclosure in verbose errors; improper inventory (beta/dev APIs exposed); default creds on related systems.
- [ ] Resource consumption limits (probe, don't DoS).
- [ ] **GraphQL** — introspection on? enumerate types/fields; BOLA/BFLA via IDs; injection in arguments; batching/alias/depth abuse (probe, don't hammer); subscription auth.
- [ ] **OAuth** — flow ID; `redirect_uri` validation (open redirect, path traversal, subdomain bypass); `state` (missing/predictable/reusable); token leakage via Referer; client-secret leakage; scope elevation; account-link takeover; PKCE.
- [ ] **JWT** — decode/inspect; `alg:none`; RS256→HS256 confusion; signature stripping/tamper; weak HMAC brute-force; `kid` injection (SQLi/traversal/`/dev/null`); `jku`/`jwk` header injection; claim-validation bypass (`exp`/`nbf`/`aud`/`iss`).

## HTTP request smuggling (only if an in-scope proxy/LB chain exists)

- [ ] Detect CL.TE / TE.CL / TE.TE via timing and header obfuscation — carefully, this can affect other users' requests, so confirm the ROE permits it and stop at detection unless cleared to exploit.
- [ ] CDN/proxy normalization differences (CRLF, obs-fold, duplicated headers); HTTP/2 downgrade quirks.

## Parser differentials — path confusion (a front proxy↔backend, **or** an app's own auth-filter↔dispatcher)

A *different axis* from smuggling: not "where does the request end" (framing) but "which route/path does each layer think this is" (URL interpretation). If a WAF/CDN/LB/gateway/upload-accelerator sits in front of a different backend, the two may normalize the same URL differently — and a front decision (auth, routing, preprocessing, cache, WAF) then applies to a *different* resource than the backend serves (→ `web-path-confusion`). **The two parsers need not be two servers:** one app's own security filter (matching a URL pattern) and its request dispatcher (which strips `;`-path-parameters and suffixes) can read the same path differently, so a `;`-segment or fake `.jsp`/`.css` suffix passes the filter as public while routing to a protected handler — no proxy in the chain (→ `web-path-confusion`). Run this sweep whenever **either** a front proxy **or** a URL-pattern auth filter is in play (the latter is nearly every Java-servlet/Spring app).

- [ ] Reach a front-gated route by a second spelling the backend normalizes the same: encoded chars (`/%61dmin`), dot-segment gaps (`/..;/admin`, `%2e%2e`), encoded/double-encoded slash (`%2f`/`%252f`), path parameters (`/admin;/`), bare-query/fragment suffix (`/api/v1/apikey?/api/v1/ping`), trailing-slash/dot, backslash, case. Confirm by **differential response** (same backend resource, two paths, two front behaviors).
- [ ] **Bypass-the-upstream-inherit-its-trust:** where a front layer is *supposed* to set/sanitize/authenticate a value (upload accelerator rewriting a temp path, edge injecting an identity header, WAF normalizing), find an input that makes it **skip that step while still forwarding** — the backend then trusts a value the proxy was meant to author (GitLab CVE-2026-85706: raw `file.path` → unauth file read).
- [ ] Cache-key confusion (web cache deception/poisoning via static-extension or normalization tricks); WAF evasion (a route/encoding the front doesn't inspect but the backend executes → chains to `web-sqli`/`web-xss`/`web-rce`).
- [ ] Detecting the differential is safe and *is* the finding; reaching the gated route / skipped-preprocessing handler and actually reading privileged data is the gated crossing — prove reachability with a benign marker or an existence/verbose-error oracle, and route content extraction through the anchor.

## Mobile-adjacent (when the target is a mobile app)

- [ ] The mobile client is a window onto the API — most findings live at the API surface above.
- [ ] Static: hardcoded secrets/keys/endpoints, insecure storage, exported components, weak cert pinning.
- [ ] Dynamic: intercept traffic (bypass pinning in the test build only), replay/tamper API calls, local data at rest.
- [ ] Deep links / IPC / WebView (JS bridges, file access, loadUrl injection).

## Client-side

- [ ] DOM XSS via JS sinks; postMessage origin checks; prototype pollution; client-side template injection.
- [ ] Sensitive data in localStorage/sessionStorage; secrets in bundled JS; source-map exposure.
- [ ] CORS misconfig (reflected origin, `null`, credentials with wildcard).

## AI-native surfaces (only if the target actually ships an AI feature)

An AI sweep applies **only when the surface really has that AI feature** — an embedded LLM/chat/agent, an MCP server/tool the app exposes or consumes, or a serialized model file it ships/loads. With no such feature the sweep is **not-applicable** (record it as N/A, name why); a present-but-untested AI feature is **not-covered** and stays on the board. Same coverage bar as everywhere else: a lead is a *candidate* until the proof-capsule discipline promotes it to *confirmed* — the judge finds the leak/injection/breach and a negative control confirms it (benign baseline vs. attack, same request otherwise).

- [ ] **AI/LLM-application sweep** → load `web-llm` — when the target embeds an LLM/chat/agent feature: prompt injection (direct + indirect), jailbreak, system-prompt/data leakage, PII/data-leakage, and LLM-layer access control (BOLA/BFLA/RBAC at the model layer), excessive agency, unbounded consumption.
- [ ] **Agentic/MCP sweep** → load `web-agentic` — when the target exposes or consumes MCP servers / agent tools: tool poisoning, cross-server shadowing, rug-pull, confused deputy, token/credential passthrough, toxic multi-tool flows, MCP supply chain.
- [ ] **Model-artifact sweep** → load `web-model-supply-chain` — when the target ships or loads serialized model files (pickle/PyTorch/Keras/GGUF/SavedModel): malicious-pickle / unsafe-deserialization / Lambda-layer injection / provenance.

---

When a section produces a lead, load the deep skill for that class and pursue it there; when it's exhausted, record the coverage note and file what you found.
