# Account Takeover (ATO) Taxonomy Reference

## Core ATO Vectors
1. **Authentication Layer**:
   - Credential stuffing / Password brute-force (lack of rate limiting).
   - MFA bypass (response manipulation, endpoint skipping, brute force).
   - Session fixation / Session hijacking.
2. **Identity & Federation (OAuth / SSO / SAML)**:
   - `redirect_uri` manipulation stealing auth codes.
   - Pre-account takeover via unverified email linking.
   - SAML assertion signature wrapping / XML signature validation flaws.
3. **Recovery & Reset Layer**:
   - Password reset Host Header poisoning.
   - Reset token leak in API response or Referer headers.
   - Predictable password reset tokens.
4. **Authorization & Profile Modification (IDOR / CSRF)**:
   - IDOR on email change endpoint (`PUT /api/user/email` with `user_id`).
   - CSRF on email / password update.
   - Mass assignment: `{"email": "attacker@evil.com", "role": "admin"}`.
5. **Client-Side & Storage (XSS / CORS / PostMessage)**:
   - Stored XSS stealing session cookies / localStorage tokens.
   - CORS misconfiguration exfiltrating authorization tokens.
   - Vulnerable PostMessage event listeners updating auth tokens or state.

## Verification Checklist
- [ ] Can an attacker gain access to an account without knowing the victim's password?
- [ ] Can an attacker change the victim's email/password without authorization?
- [ ] Can an attacker force account linkage via OAuth/SAML?
- [ ] Does password reset invalidate all existing active sessions?
