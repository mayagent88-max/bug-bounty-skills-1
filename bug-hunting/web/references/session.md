# Session Management & Fixation Reference

## Attack Surface Signals
- Cookies: `PHPSESSID`, `JSESSIONID`, `ASPNET_SessionId`, `session`, `connect.sid`, `sid`.
- Session tokens in query parameters, headers, or localStorage.
- Login, logout, role-change, and password-reset actions.
- Concurrent sessions, multi-tab workflows, long-lived session behavior.

## Testing & Attack Patterns
1. **Session Fixation**:
   - Obtain an unauthenticated session ID / cookie.
   - Authenticate the account.
   - Verify if the pre-authentication session cookie remains valid post-authentication.
2. **Session Termination & Invalidation**:
   - Logout test: Capture active session token, invoke logout endpoint, test if token still accesses authenticated resources.
   - Password change test: Change password as User A; verify if previously issued tokens from other devices/browsers are revoked.
   - Role change test: Revoke admin privileges; verify if existing session immediately loses admin access.
3. **Cookie Security Attributes**:
   - Missing `HttpOnly` (enables token theft via XSS).
   - Missing `Secure` (leaks session over unencrypted HTTP).
   - `SameSite=None` without strict origin validation (enables CSRF).
   - Loose `Domain=.example.com` (allows subdomain takeover or rogue subdomain session hijacking).
4. **Session Hijacking & Token Predictability**:
   - Sequential, timestamp-based, or low-entropy PRNG session generation.
   - Token reflection in server access logs via URL parameters (`?session_id=...`).

## Common Root Causes
- Failure to regenerate session identifiers upon privilege level transitions (login, sudo-mode, 2FA validation).
- Stateless JWT or server cache missing an active revocation/denylist mechanism.
- Session stored entirely client-side without cryptographic tampering protection.

## Exploit Chains
- **Session Fixation + XSS / CSRF → Account Takeover**: Attacker forces victim's browser to adopt a known session identifier prior to victim logging in.
- **Inadequate Invalidation → Persistent Access**: Attacker retains unauthorized session indefinitely even after victim resets password.
