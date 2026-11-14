# Password Reset Flaws Reference

## Attack Surface Signals
- Endpoints: `/forgot-password`, `/reset-password`, `/auth/recover`, `/api/v1/users/password/reset`.
- Password reset token delivery via email, SMS, or security questions.

## Vulnerability Patterns & Bypasses
1. **Host Header Poisoning on Password Reset**:
   - Send reset request with modified header: `Host: attacker.com` or `X-Forwarded-Host: attacker.com`.
   - Application generates reset link using poisoned host (`https://attacker.com/reset?token=XYZ`).
   - Victim clicks link in email, sending reset token directly to attacker server logs.
2. **Token Leakage in HTTP Responses & Referers**:
   - Reset token returned directly in JSON response body upon requesting reset: `{"status": "ok", "token": "123456"}`.
   - Reset page loads external 3rd-party scripts (analytics, CDNs); reset URL leaked via `Referer` header.
3. **Predictable / Weak Token Generation**:
   - Tokens based on timestamps, MD5(email), sequential integers, or low-entropy PRNG.
4. **Parameter Pollution & Recipient Overriding**:
   - Submit multiple email parameters: `email=victim@target.com&email=attacker@evil.com` or `{"email": ["victim@target.com", "attacker@evil.com"]}`.
5. **IDOR on Reset Confirmation**:
   - Reset confirmation endpoint accepts `user_id` alongside token, but validates token globally or ignores mismatched user IDs.
6. **Pre-Authentication Session Overwrite**:
   - Resetting password while logged in as another user overrides victim account.

## Exploit Chains
- **Host Header Poisoning / Token Leakage → Zero-Interaction Account Takeover**: Attacker requests password reset for target email and obtains reset token without victim interaction or via single click.
