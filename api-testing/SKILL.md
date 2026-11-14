---
name: api-testing
description: "API security testing for a pentest-team engagement — REST/gRPC/WebSocket surfaces and the OWASP API Top 10: BOLA (API1), broken auth, BFLA (API5), mass assignment (API6), unrestricted resource consumption (API4), improper inventory (API9), plus business-logic abuse: workflow chaining, race conditions, GraphQL batching, pagination exfil, webhook/SSRF, and JWT manipulation, with curl/grpcurl/websocat/jwt_tool/Arjun. Load it when the appsec-triage API-testing sweep turns up a BOLA/BFLA/mass-assignment/resource-consumption/inventory lead on a claimed target."
---

# API Security Testing — under the engagement protocol

Deep methodology for the API class. You reach here from the `appsec-triage` API-testing sweep with a lead on a surface you already own on the board.

## Under the engagement protocol

- **Claimed and in-scope only.** Every request goes to a target you own on the board and that is on the `ROE.md` allowlist — REST host, gRPC port, and WS endpoint alike. Enumerating API versions or "internal" prefixes never licenses hitting a host off the allowlist.
- **Prove with a marker, not a dump.** Confirm BOLA/BFLA against a *planted marker record* or a *second test tenant* — never enumerate real customer objects or page a table out to "show impact". Excessive-data-exposure is proven by pointing at the extra field, not by exfiltrating the set. No-real-data means the proof is a marker or a hash.
- **Read before write; destructive, RCE, or outward-facing is gated.** Mass-assignment that flips `is_admin`, state mutation, coupon/balance races, and SSRF are destructive or outward-facing — mark the surface blocked and route through the lead to the anchor for the human's explicit go before you run them. OOB/SSRF/webhook callbacks point at a **benign in-scope listener only** — never `169.254.169.254`, never a live external puller; reachability is the finding, the live pull is the incident.
- **Rate-limit and coordinate load.** Batching, race harnesses, ID enumeration, and version brute-forcing hammer a shared target and trip a WAF/gateway ban for the whole team. Throttle, cap concurrency, coordinate load on the board, and back off the moment the target slows.
- **Log and file** per PROTOCOL §Evidence and §Findings — findings in the `appsec-reporting` format, with a re-runnable reproduction another operator could follow.

## Quick workflow

1. Map the surface: OpenAPI/Swagger, gRPC reflection, WS endpoints, and undocumented routes.
2. Enumerate auth mechanisms — API keys, OAuth, JWT, session tokens; note which test accounts you hold.
3. BOLA/IDOR — swap object IDs across authenticated contexts and HTTP methods.
4. BFLA — probe admin/privileged functions with a low-priv token; mass-assignment for forbidden fields.
5. Resource consumption, business-logic chains, race conditions, GraphQL/pagination abuse — probe, don't DoS.
6. File each confirmed finding with a clean marker-based reproduction and remediation.

## BOLA / IDOR (API1)

Capture a legitimate request carrying an object id, replay it with an id you own on a second tenant / marker:

```bash
# Sequential + UUID sweep — keep it to YOUR marker range, throttle, cap the count
for id in $(seq 1000 1010); do
  curl -s -o /dev/null -w "id ${id} -> %{http_code}\n" \
    -H "Authorization: Bearer $TOKEN_A" \
    "https://<in-scope>/api/v1/users/${id}/orders"; sleep 0.3
done
```

Authorization is often enforced on `GET` but not on write verbs — test the method matrix against one id:

```bash
for m in GET PUT PATCH DELETE; do
  curl -s -o /dev/null -w "$m -> %{http_code}\n" -X "$m" \
    -H "Authorization: Bearer $TOKEN_A" -H "Content-Type: application/json" \
    -d '{"status":"cancelled"}' \
    "https://<in-scope>/api/v1/users/1002/orders/5001"
done
```

Stop at the first cross-tenant read of a marker — that proves the break. Do not walk the range.

## Broken auth & excessive data exposure

```bash
# Compare the full response against what the UI renders — flag internal IDs, emails, hashes, roles
curl -s -H "Authorization: Bearer $TOKEN" "https://<in-scope>/api/v1/users/me" | jq .
# Token lifecycle: expired / pre-password-change / malformed bearer
for v in "" "null" "Bearer" "Bearer "; do
  curl -s -o /dev/null -w "'$v' -> %{http_code}\n" -H "Authorization: $v" \
    "https://<in-scope>/api/v1/users/me"
done
```
Rate-limit-absence on login is proven with a **short** burst until the first `429` or ~15 tries — never a full credential-stuffing run (that is DoS and no-real-data).

## BFLA (API5) & mass assignment (API6)

```bash
# BFLA — privileged functions with a low-priv token (read probes first)
for ep in "GET /api/v1/admin/users" "GET /api/v1/admin/config" "GET /api/v1/internal/metrics"; do
  m=${ep%% *}; p=${ep#* }
  curl -s -o /dev/null -w "$m $p -> %{http_code}\n" -X "$m" \
    -H "Authorization: Bearer $REGULAR_USER_TOKEN" "https://<in-scope>$p"
done
```
```bash
# Mass assignment — inject a forbidden field against YOUR OWN account, read back the echo.
# Flipping is_admin true is a privilege change: confirm the field is REFLECTED, then STOP and
# route the actual escalation through the lead to the anchor before acting on it.
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"marker","role":"admin","is_admin":true}' \
  "https://<in-scope>/api/v1/users/me" | jq '{role,is_admin}'
```
Also try JSON→form/XML content-type switching, `X-HTTP-Method-Override`, and duplicate-key parameter pollution to slip fields past method/format-scoped controls.

## Unrestricted resource consumption (API4)

Probe limits — never exhaust them.

```bash
# Rate-limit headers over a short, throttled burst
for i in $(seq 1 10); do
  curl -s -D - -o /dev/null -H "Authorization: Bearer $TOKEN" \
    "https://<in-scope>/api/v1/search?q=test" | grep -iE "x-ratelimit|retry-after"; sleep 0.3
done
# Oversized page size / payload — send ONE probe and read the response, do not loop it
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://<in-scope>/api/v1/products?per_page=100000" | jq 'length'
```
ReDoS, XML billion-laughs, and query-depth DoS are **availability-affecting** — demonstrate the primitive with a single small probe and reasoned scaling, mark the surface blocked, and route the real DoS proof through the anchor.

## Business logic & race conditions

Map the intended flow, then deviate — skip-payment-to-confirm, add-item/calc/remove, negative quantities, currency confusion. Prove with a **marker transaction you can reverse**, respect no-real-data.

Race conditions (coupon re-redeem, balance double-spend) mutate state — keep parallelism low, use a marker coupon/account, and gate any money-moving proof through the anchor:

```bash
# Low-concurrency race probe against a marker single-use coupon (n small, not 200)
seq 1 10 | parallel -j 10 'curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  -H "Authorization: Bearer '"$TOKEN"'" -H "Content-Type: application/json" \
  -d '\''{"coupon_code":"MARKER-SINGLE-USE"}'\'' "https://<in-scope>/api/v1/cart/coupon"'
```

## GraphQL, pagination, webhooks

```bash
# Introspection (schema leak) + a bounded batch (amplification signal, not a brute run)
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{ __schema { mutationType { fields { name } } } }"}' \
  "https://<in-scope>/graphql" | jq '.data.__schema.mutationType.fields[].name'
```
Batching/alias amplification and deep nesting are DoS/brute vectors — send a small proof-of-concept batch to show the control gap, not a wordlist run. Pagination: forge a cursor to read a **marker** record (`base64 '{"id":<marker>}'`), and flag `sort=password`-style field leaks — don't page the set out.

Webhook/SSRF: register a callback to a **benign in-scope listener** and confirm the server calls it; that proves callback hijack and SSRF reachability without pointing at cloud metadata. Any internal-target SSRF is proven by reaching a benign in-scope endpoint, then routed to the anchor.

## gRPC & WebSocket

```bash
grpcurl -plaintext <in-scope>:50051 list                     # reflection enum
grpcurl -plaintext -H "authorization: Bearer $TOKEN_A" \
  -d '{"user_id":"<marker>"}' <in-scope>:50051 svc.UserService/GetUser   # BOLA
# metadata injection: x-user-role: admin, x-internal-service: true
websocat -H "Origin: https://evil.example.com" "wss://<in-scope>/ws"     # origin/CSWSH check
```
For WS, send the tampered field (`user_id`, admin message types, `../` channel) inside the JSON frame the app uses; CSWSH is confirmed by an authenticated connection succeeding from a foreign Origin — log the echo, don't relay data off-scope.

## Improper inventory (API9)

```bash
# Version + doc/debug surface — every path stays on the in-scope host
for v in v0 v1 v2 v3 internal beta dev; do
  curl -s -o /dev/null -w "$v -> %{http_code}\n" -H "Authorization: Bearer $TOKEN" \
    "https://<in-scope>/api/${v}/users/me"
done
for ep in /swagger.json /openapi.json /graphql /actuator/env /metrics /debug; do
  c=$(curl -s -o /dev/null -w "%{http_code}" "https://<in-scope>${ep}"); [ "$c" != 404 ] && echo "$ep -> $c"
done
```
Old versions with weaker controls, exposed docs, and leaked keys (client JS bundles, verbose errors — grep, don't harvest) are the inventory findings. Note any WAF/gateway present and what bypassed it — control efficacy is itself reportable.

## Remediation (for the finding)

1. **Fix** — enforce object- and function-level authorization server-side on every method and version (deny-by-default, check the caller owns the object); bind requests to an explicit allowlist of writable fields (no blanket model binding); validate `redirect_uri`/webhook URLs against an allowlist; sign and validate JWTs with a fixed algorithm.
2. **Defense in depth** — per-route rate limits and payload/pagination caps, GraphQL query depth/complexity limits and batching caps, retire/authenticate old API versions, remove debug/doc endpoints from prod, least-privilege service tokens.
3. **Detection** — gateway rules on cross-object access sequences, out-of-order workflow steps, oversized batches/payloads, and callbacks to non-allowlisted destinations.

Write it up in the `appsec-reporting` finding format, **CWE-639 / CWE-285, OWASP API Top 10 (2023)**, with the marker-based reproduction.

## Related skills

- `web-idor` — deep object-level (BOLA) enumeration and cross-tenant proof techniques.
- `web-graphql` — GraphQL-specific testing (introspection, batching, Relay node IDs).
- `auth-jwt` / `auth-oauth` — attacks on the tokens and authorization flows behind the API.
