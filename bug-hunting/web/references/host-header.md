# Host Header Injection Reference

## Attack Surface Signals
- Applications generating absolute URLs (links, redirects, password reset tokens, canonical tags) based on the incoming `Host` header.
- Headers: `Host`, `X-Forwarded-Host`, `X-Host`, `X-Forwarded-Server`, `Forwarded`.

## Testing Patterns & Payloads
1. **Arbitrary Host Header Injection**:
   - `Host: attacker.com` (Check if response reflects `attacker.com` in links, scripts, or redirects).
2. **Duplicate Host Headers / Ambiguity**:
   - Send two Host headers:
     ```http
     Host: target.com
     Host: attacker.com
     ```
3. **Port & Delimiter Injection**:
   - `Host: target.com:attacker.com`, `Host: target.com@attacker.com`, `Host: target.com:80`.
4. **Host Header Password Reset Poisoning**:
   - Initiate password reset with `Host: attacker.com`. Reset link in email points to `https://attacker.com/reset?token=...`.
5. **Web Cache Poisoning via Host**:
   - If Host header is unkeyed or partially keyed, poison cached page with malicious asset domain.

## Exploit Chains
- **Host Header Poisoning → Account Takeover**: Intercepting password reset tokens.
- **Host Header Injection → Cache Poisoning / SSRF**.
