---
name: appsec-recon
description: "Attack-surface mapping for a pentest-team engagement — turning an in-scope app into a tested map: content and endpoint discovery, technology fingerprinting, API-contract capture (OpenAPI/GraphQL), JavaScript analysis for endpoints and secrets, auth-flow mapping, and tenant/role modeling. Load it at the start of a surface, or when building the coverage board. Feeds the vault's per-app knowledge (auth flows, where bugs cluster) so re-tests start from the map."
---

# AppSec Recon — mapping the attack surface

Recon on an appsec engagement is not open-ended internet OSINT — it is turning each **in-scope** app into a map the team tests against and the vault remembers. The output is board rows (testable surfaces), a target inventory in `CONTRACT.md`, and — for a team that will re-test this app — durable per-app knowledge in the vault.

## Under the engagement protocol

- **Scope is the fence.** Enumerate within the `ROE.md` allowlist. Discovery that surfaces an out-of-scope host (a dangling subdomain, a related domain) is a `FOLLOW-UPS.md` entry, not a new target — never probe it.
- **Passive before active; gentle when active.** Prefer contract capture and traffic observation over noisy brute-forcing on a shared/production target; throttle content discovery.
- **Recon feeds the board and the vault.** Each mapped surface becomes a board row with an owner; each durable fact about the app (its auth flow, its stack, its tenant model) is vault material for the next re-test, subject to the engagement's data-handling mode.
- **Set the `<app-key>` first.** Recon chooses this app's vault key — a stable host/app slug (`acme-billing`, `app.acme.io`) that stays the same across re-tests so the per-app record accretes under one name, not a new one each quarter — and records it on ENGAGEMENT.md's `Vault:` line, so every operator and the coded assist address the same `vault/per-app/<app-key>/` (PROTOCOL §Vault). Derive it once from the primary host/app name; keep it stable even as hostnames churn.
- **Check the vault first — but pull the slice, not the vault.** If the team has tested this app before, its per-app record lives under `vault/per-app/<app-key>/` (PROTOCOL §Vault): the auth-token minter, the surface map, the prior findings' `confirmed/*.json` capsule-refs, and the `failures.ndjson` of dead-ends and near-misses already walked. **Retrieve only the slice matching this surface's `<app-key>` and tags — never the whole vault** — because dumping the whole estate's memory into context buries this surface's signal (context-rot guard). Start from that slice, and re-verify it (apps change; a stale token script fails, a stale "where bugs cluster" note misleads).

## What to map

### Content and endpoints
- Browse the app thoroughly first; catalogue every data-entry point (forms, params, uploads, search, API calls seen in the proxy).
- Content discovery (directory/file brute-force) with a sensible rate limit and a stack-appropriate wordlist.
- Capture the JS bundle: enumerate every script, extract endpoints, param names, feature flags, and hardcoded secrets/keys; check for exposed source maps.
- Endpoints from the bundle/HTML/observed traffic are only the ones the client *uses*: record *how* each was found, and mark privileged prefixes (`/admin/*`, internal APIs) for active enumeration by the owning operator — **shadow** routes (an admin write no UI calls) are absent from a client-derived map by definition.

### Technology fingerprint
- Framework, server, CDN/WAF/gateway (headers, cookies, error pages), cache layer behavior.
- Research known vulns for the exact stack/versions — a fingerprint that names a version with a public CVE is a lead before you send a single payload.
- **A front layer of a different make than the backend is a parser-differential lead** — the two may normalize URLs differently. Flag it on the board for the owning operator's `appsec-triage` parser-differential sweep (→ `web-path-confusion`), and map the seam as a trust boundary (below).

### API contract
- Find and capture OpenAPI/Swagger, GraphQL schema (introspection), WSDL. Diff the declared contract against traffic you actually observe — undocumented endpoints and shadow/beta APIs are where access-control bugs hide.
- Note versions (`/v1/` vs `/v3/`); older versions often skip newer authz checks.

### Auth flow (the high-value map)
- Map how the app authenticates end to end: the login request(s), the token/cookie issued, how it's carried (header/cookie/storage), refresh/rotation, MFA, and logout behavior.
- **Turn it into an instrument.** The single most reusable artifact recon produces is a script that mints a valid session/token from a set of test creds — because every operator on this engagement, and every re-test after it, needs authenticated access and should not re-derive the flow. Build it, put creds in the environment or a secrets store (never hardcoded), and promote it to the vault as this app's token minter. Re-verify it on the next run.
- Model the **tenants and roles**: which accounts exist, what each can see, where the tenant boundary is. This is what the access-control operator (`appsec-triage` §Access control) tests against — hand it over on the board.

### Trust boundaries and integrations
- Third-party integrations, SSO/OAuth providers, webhooks, cloud metadata reachability (note it; prove benignly if it becomes an SSRF lead).
- Where user input crosses a boundary (client→server, service→service, into a template/query/file op) — these are the injection surfaces the deep skills target.
- **The request pipeline is itself a boundary — map its topology.** Count the hops in front of the app and name each (TLS terminator, CDN, WAF, load balancer, API gateway, upload/body accelerator), then pin down the two responsibilities that decide the parser-differential class: *which layer decodes/normalizes the URL*, and *which layer decides on it* (auth, routing, cache key, body-buffering). When decode and decide live in **different components**, the seam between them is a differential surface — and any value the front is supposed to author for the backend (a rewritten upload path, an injected identity header, a "came-via-proxy" token) is a trust the backend places in the upstream that a route-miss can break. Hand the seam to the owning operator with the front/backend stack noted (→ the fingerprint lead above, `appsec-triage` parser-differential sweep, `web-path-confusion`).

## Output

1. **Board rows** — one per testable surface, with a surface tag (web/api/auth/mobile/client-side, or whatever cut this target calls for) so the lead can staff it.
2. **`CONTRACT.md`** — the target inventory: hosts/endpoints in scope, API contracts, test accounts and which is which, the auth mechanism.
3. **Vault (per-app)** — write under `vault/per-app/<app-key>/` (PROTOCOL §Vault): the prose map in `README.md` (auth flow, stack, tenant/role model, request-pipeline / URL-normalization topology — who decodes vs who decides — and "where the bugs cluster" once the engagement finds out), with the auth-token minter promoted to `instruments/`. The `failures.ndjson` and `confirmed/<id>.json` capsule-refs fill as operators cover surfaces and file findings — so next quarter's re-test starts here, replays the baseline, and skips the dead-ends, instead of starting at the login page.

Recon is done for a surface when its board row exists with an owner, the auth path is understood (and scripted where it repeats), and the contract is captured. **What recon hands over is a lead, not a coverage boundary** — a surface is not `covered` when its client-derived endpoints are tested, only when its privileged prefixes are actively enumerated too (`appsec-triage` §Access control). Then the operator claims and tests it with the relevant deep skill. **Every element recon turns up that the coverage matrix does not already list goes in with `pt.coverage_propose`**: an endpoint group, feature, admin prefix, host, role or tenant, with where you saw it (JS file, spec, response). A target on the ROE allowlist becomes a matrix row at once. Anything else waits for the anchor. That proposal is how a discovered surface becomes work someone must close, rather than a line in your notes.
