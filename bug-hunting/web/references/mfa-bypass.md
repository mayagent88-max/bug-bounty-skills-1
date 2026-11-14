# MFA / 2FA Bypass Reference

## Attack Surface Signals
- Post-login 2FA prompt endpoints: `/auth/2fa`, `/verify-otp`, `/mfa/challenge`, `/api/v1/auth/totp`.
- Multi-factor enrollment, recovery codes, SMS/Email OTP, Push notifications.

## Testing & Bypass Patterns
1. **Direct Endpoint Navigation / Flow Skipping**:
   - Authenticate with primary credentials (username/password).
   - When redirected to 2FA page, directly request protected endpoints (e.g. `/dashboard`, `/api/user/profile`).
2. **2FA Response Manipulation**:
   - Intercept 2FA submission response (e.g. `{"success": false, "error": "Invalid OTP"}`).
   - Modify response to `{"success": true, "status": "verified", "token": "..."}` or HTTP `200 OK`.
3. **Session / Cookie Swapping**:
   - Log in to Account A, pass 2FA.
   - Log in to Account B, hit 2FA prompt, substitute Account A's post-2FA session cookie or auth header.
4. **Brute Force & Missing Rate Limits**:
   - 4-digit (10,000 combinations) or 6-digit (1,000,000 combinations) OTP endpoints lacking rate limits.
   - Rate limit bypass via IP rotation, header spoofing (`X-Forwarded-For`), or race conditions.
5. **Alternative Authentication Flow / Legacy APIs**:
   - Mobile API endpoints (`/api/mobile/v1/login`, `/api/v2/authenticate`) that do not enforce MFA.
   - OAuth / SSO / SAML login flows that bypass local MFA enforcement.
   - Password reset flow automatically authenticating user into active session without prompting for MFA.
6. **Reused / Leaked Recovery Codes**:
   - Backup codes not invalidated upon initial use.
   - Backup codes exposed in API responses or HTML comments during initial setup.

## Exploit Chains
- **Primary Credential Leak + MFA Bypass → Account Takeover**: Full unauthorized access to protected accounts despite user having enabled two-factor authentication.
