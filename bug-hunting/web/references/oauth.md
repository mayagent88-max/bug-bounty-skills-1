# OAuth 2.0 & OIDC Vulnerabilities Reference

## Attack Surface Signals
- Endpoints: `/oauth/authorize`, `/oauth/token`, `/oauth/callback`, `/v1/auth/sso`, `/connect/authorize`.
- Parameters: `client_id`, `redirect_uri`, `response_type`, `scope`, `state`, `code`, `id_token`.
- Social logins: "Log in with Google / Facebook / Apple / GitHub / Okta".

## Attack Techniques & Flaw Patterns
1. **Flawed `redirect_uri` Validation**:
   - **Subdomain / Path Traversal**: `https://victim.com.attacker.com`, `https://victim.com/oauth/callback/../../attacker`.
   - **Open Redirect Chaining**: `redirect_uri=https://victim.com/redirect?url=https://attacker.com`.
   - **Parameter Injection / Parameter Pollution**: `redirect_uri=https://victim.com/callback%26param=value`.
   - **Regex / Wildcard Bypasses**: `https://victim.com@attacker.com`, `https://victim.com#@attacker.com`.
2. **Missing / Predictable `state` Parameter (OAuth CSRF)**:
   - Authorization flow lacks `state` parameter or fails to validate it on callback.
   - Attacker initiates OAuth flow, intercepts authorization `code`, and tricks victim into submitting callback to bind attacker's account to victim.
3. **Pre-Account Takeover via Account Linking (Unverified Email)**:
   - Attacker creates account on IdP with victim's email (if IdP doesn't verify email ownership).
   - Attacker logs in via OAuth on target site; target auto-merges account based on matching email without password confirmation.
4. **Authorization Code Replay & Leakage**:
   - Codes leaked via `Referer` headers to third-party analytics/scripts on callback pages.
   - Reusable auth codes: Server fails to invalidate authorization code immediately after single token exchange.
5. **Implicit Grant (`response_type=token`) Flaws**:
   - Token exposed in URL fragment `#access_token=...` extracted via open redirects, DOM sinks, or cross-domain scripts.

## Exploit Chains
- **`redirect_uri` Leakage → Account Takeover**: Intercept authorization `code` / `access_token` to authenticate directly as victim.
- **Account Linking Confusion → Silent Persistence**: Attacker links their OAuth identity to victim's account to retain permanent backdoor access.
