# CSRF (Cross-Site Request Forgery) Reference

## Attack Surface Signals
- State-changing actions performed via `POST`, `PUT`, `DELETE`, or `PATCH`.
- Endpoints: Email update, password change, 2FA disable, profile edit, API key generation, bank transfer.
- Authentication relies on ambient credentials (session cookies, basic auth, Windows NTLM).

## Bypass Techniques & Detection Patterns
1. **HTTP Method Switching**:
   - Change `POST` to `GET`, `PUT`, `HEAD`, or `OPTIONS` (e.g. `GET /api/user/email?email=attacker@evil.com`).
2. **Token Validation Flaws**:
   - **Token Removal**: Completely delete the `csrf_token` parameter / header from the request.
   - **Empty / Null Token**: Submit `csrf_token=` or `{"csrf_token": null}`.
   - **Token Length Check Only**: Submit any arbitrary string of matching length.
   - **Unlinked / Static Token**: Use a valid CSRF token harvested from Account B against Account A.
3. **Content-Type Mutation**:
   - Change `application/json` to `text/plain`, `application/x-www-form-urlencoded`, or `multipart/form-data`.
   - Submit plain text containing pseudo-JSON: `{"email":"attacker@evil.com", "ignore":"` using HTML form.
4. **SameSite Cookie Quirks**:
   - `SameSite=Lax` default allows top-level `GET` navigation requests to carry cookies.
   - 2-minute window exemption (`SameSite=Lax+POST` bypass in older Chromium versions).
   - Missing `SameSite` attribute defaulting to browser-specific behavior.
5. **Referer / Origin Header Bypasses**:
   - Strip `Referer` using `<meta name="referrer" content="no-referrer">`.
   - Regex bypass in origin checks: `https://victim.com.attacker.com` or `https://attacker.com/victim.com`.

## Exploit Chains
- **CSRF → Account Takeover**: Forcing victim's browser to submit a password reset or change registered recovery email.
- **CSRF → 2FA Deactivation**: Submitting request to disable MFA when MFA endpoint lacks anti-CSRF protections.
