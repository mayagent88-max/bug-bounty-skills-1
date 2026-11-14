---
name: auth-oauth
description: "OAuth 2.0 / OIDC abuse testing for a pentest-team engagement — redirect_uri validation bypass (open-redirect, path traversal, subdomain), state CSRF and forced account-linking, authorization-code injection/substitution, token leakage via Referer, client-secret leakage, scope elevation, PKCE downgrade, and strict token-claim (aud/iss/exp) validation, with Burp/ZAP flow interception. Load it when the appsec-triage API-testing (OAuth) sweep turns up an OAuth/OIDC lead on a claimed auth/API target."
---

# OAuth / OIDC Abuse — under the engagement protocol

Deep methodology for the OAuth/OIDC class. You reach here from the `appsec-triage` API-testing (OAuth) sweep with a lead on an auth surface you already own on the board.

## Under the engagement protocol

- **Claimed and in-scope only.** Every leg of the flow — authorization endpoint, callback, token endpoint, IdP — must be a target on the `ROE.md` allowlist. The client app and its IdP are often different hosts: both must be in scope before you tamper with the round-trip.
- **Prove with a marker, not a hijack.** Confirm a `redirect_uri` bypass or code theft against *your own* two test accounts (link attacker-account → victim-marker-account), and prove the primitive — never phish, take over, or link a real user. No-real-data means a planted marker account, not a live customer's identity.
- **Callbacks and code exfil go to a BENIGN in-scope listener only.** A stolen authorization code or leaked token is redirected to a listener you own *on the allowlist* — never to a live external webhook, Burp Collaborator public instance, or attacker domain. An SSRF `redirect_uri` (e.g. `169.254.169.254`) is proven by reaching a benign in-scope endpoint; pulling real cloud metadata is the incident the ROE exists to prevent.
- **Read before write; account-linking and takeover are gated.** Actually completing a takeover, disabling MFA via a linked account, or driving a real refresh-token family revocation is destructive/outward-facing — mark the surface blocked and route through the lead to the anchor for the human's explicit go. A demonstrated code-theft or a `state`-absent CSRF PoC makes the point without seizing an account.
- **Rate-limit the IdP.** Device-code polling, refresh-token rotation probes, and HMAC brute-force can lock accounts or trip IdP throttling that blocks the whole team. Throttle, coordinate load on the board, and never brute a `client_secret` or HMAC key at volume against a live authorization server.
- **Log and file** per PROTOCOL §Evidence and §Findings — findings in the `appsec-reporting` format, with a reproduction another operator could re-run against the marker accounts.

## Quick workflow

1. Fingerprint the flow: intercept the login in Burp/ZAP, read `response_type`, `redirect_uri`, `scope`, `state`, `nonce`, `code_challenge`. Pull `/.well-known/openid-configuration` for endpoints and supported params.
2. Attack `redirect_uri` validation first — it is the highest-yield leg.
3. Test `state`/`nonce` integrity (CSRF, forced linking, code injection).
4. Chase token leakage (Referer, URL fragment, storage) and secret leakage (source/git).
5. Probe scope elevation and PKCE downgrade.
6. Confirm impact across your two marker accounts; file with a clean reproduction.

## Flow fingerprinting

```
GET /.well-known/openid-configuration        # endpoints, response_types, PKCE support
# Authorization Code (preferred, has PKCE):
/authorize?client_id=...&redirect_uri=https://<in-scope>/callback&response_type=code&scope=openid%20profile&state=<rnd>&code_challenge=<...>&code_challenge_method=S256
# Implicit (deprecated — token in fragment, higher leak risk):
/authorize?...&response_type=token
```
ID token vs access token: an API that accepts an *ID token* as a bearer credential is a finding — check `token_type`/`aud`.

## redirect_uri validation bypass

Register / observe the legit `redirect_uri`, then test the allowlist match. Point exfil at a listener **on the allowlist**:

```
# Exact-match bypasses — swap in your in-scope listener as the "attacker" sink
redirect_uri=https://<in-scope>.evil-but-in-scope/cb      # subdomain / suffix confusion
redirect_uri=https://<in-scope>/callback/../../oob        # path traversal
redirect_uri=https://<in-scope>/callback%2f@oob-listener  # parser confusion (@, %2f, \, #, ?)
redirect_uri=https://<in-scope>/callback%23@listener
redirect_uri=https://<in-scope>.attacker           # missing-separator / prefix match
```
Also test open-redirect chaining: if a trusted in-scope host has an open redirect, a strict allowlist can still leak the code through it. Prove the code lands on your in-scope listener; do not forward a real user's code anywhere.

## state / nonce integrity (CSRF, forced linking, code injection)

- **Missing/predictable/reusable `state`** → login CSRF and **forced account-linking**: capture a valid callback URL before the code is consumed, and (with your marker accounts) show it links attacker's social identity to the victim marker. Deliver only to your own marker session — never to a real user.
- **Authorization-code injection / substitution**: inject a code minted in the attacker session into the victim session. `state`↔session binding + PKCE `code_verifier` should defeat it; if they don't, that's the finding.
- **OIDC `nonce`** missing or unmatched → replay of ID tokens.

## Token & secret leakage

```
# Referer leak: token/code in URL → does an off-page resource (img, analytics, third-party JS) leak it in Referer?
# Implicit flow fragment (#access_token=...) is especially Referer/history-prone.
# Storage: token in localStorage (XSS-reachable) vs httpOnly cookie.
```
Client-secret leakage — grep the client JS bundle, source maps, mobile binary, and public git for `client_secret`, hardcoded keys, and IdP endpoints:
```bash
# against your captured, in-scope JS only
grep -RniE 'client_secret|refresh_token|"kid"|private_key' ./bundle
```

## Scope elevation & PKCE downgrade

```
# Scope elevation: request broader scope than the client should get; or on refresh, widen it.
scope=openid profile   ->   scope=openid profile admin
# PKCE downgrade: strip code_challenge, or force method S256 -> plain, or omit code_verifier at token exchange.
POST /token  grant_type=authorization_code&code=<code>&redirect_uri=...     # (no code_verifier)
```
If the token endpoint issues tokens despite a missing/mismatched `code_verifier`, PKCE is not enforced — record it.

## Token-claim validation (OIDC)

Weak `aud`/`iss`/`exp`/`azp` checks enable cross-tenant and confusion attacks (IdP confusion: code from tenant A's IdP exchanged at tenant B's token endpoint). JWT-specific tampering — `alg:none`, RS256→HS256 confusion, `kid`/`jku`/`jwk` injection — lives in the JWT deep skill; pivot there and cite the chain. RCE-adjacent escalation (SSRF-to-metadata via `jku`, `kid` traversal to `/dev/null`) is gated through the anchor.

## Automation (throttled, in-scope)

Intercept and replay with Burp Suite / OWASP ZAP; analyze tokens with `jwt_tool`. Keep flow-replay counts low against a live IdP; never point a scanner or a `client_secret`/HMAC brute at a host outside the allowlist.

## Remediation (for the finding)

1. **Fix** — enforce exact-string `redirect_uri` matching against a pre-registered allowlist (no wildcards, prefix, or path traversal); require a cryptographically random, single-use `state` bound to the session; mandate PKCE (`S256`) for all clients and validate `code_verifier` at exchange; validate `nonce` for OIDC.
2. **Defense in depth** — strict token-claim validation (`aud`/`iss`/`exp`/`azp` with ≤60s skew); short-lived access tokens (5–15 min) with refresh-token rotation and reuse-detection (revoke the family on reuse); never store tokens in `localStorage` — memory-only or `__Host-` `HttpOnly; Secure; SameSite` cookies; APIs must reject ID tokens as bearer credentials; keep `client_secret` server-side only. For high-assurance flows, add PAR/JAR/JARM and sender-constrained tokens (DPoP/mTLS).
3. **Detection** — alert on `redirect_uri` values off the registered allowlist, on authorization requests missing `state`/PKCE, and on refresh-token reuse.

Write it up in the `appsec-reporting` finding format, CWE-287 / CWE-346 / A07:2021 Identification & Authentication Failures, with the marker-account reproduction.

## Related skills

- `web-open-redirect` — the `redirect_uri` / open-redirect filter-bypass mechanics an OAuth token-theft chain depends on.
- `auth-jwt` — attacking the tokens an OAuth/OIDC flow issues.
