# Brute Force & Rate Limiting Reference

## Attack Surface Signals
- Login endpoints, OTP/2FA verification, password reset requests, voucher redemption, invite code validation.
- Response codes: `429 Too Many Requests`, `403 Forbidden`, `400 Bad Request`.

## Four Rate-Limit States to Differentiate
1. **Unconstrained**: No rate limiting whatsoever. Infinite requests succeed.
2. **Client-Controlled (IP/Header bound)**: Rate limits based on headers attacker can spoof.
3. **Account-Bound**: Limit tied to target username/email (prevents targeted brute force, but allows password spraying).
4. **Strict Global**: Hard limit across all infrastructure.

## Bypass Techniques
1. **IP Spoofing Headers**:
   - `X-Forwarded-For: 127.0.0.1`, `X-Real-IP: 10.0.0.{1..255}`
   - `X-Originating-IP: ...`, `Client-IP: ...`, `True-Client-IP: ...`
   - Send multiple IPs in chain: `X-Forwarded-For: 1.1.1.1, 2.2.2.2`.
2. **Path & Parameter Obfuscation**:
   - `/api/v1/login`, `/api/v1//login`, `/api/v1/login/`, `/api/v1/login.json`.
   - Case modification: `/api/v1/Login`.
3. **Batching / Array Requests**:
   - GraphQL batching: Multiple `mutation { login(...) }` inside a single HTTP request.
   - JSON array batching: `[{"username":"admin","password":"1"},{"username":"admin","password":"2"}]`.
4. **Credential Spraying (1 password across N users)**:
   - Evades per-user attempt lockouts by trying one common password against thousands of distinct accounts.
5. **HTTP/2 Multiplexing & Race Windows**:
   - Send concurrent bursts within sub-second windows before rate-limit counter increments.

## Exploit Chains
- **Rate Limit Bypass → OTP Recovery → ATO**: Brute forcing 6-digit MFA or password reset codes to hijack accounts.
