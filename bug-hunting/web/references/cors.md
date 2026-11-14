# CORS (Cross-Origin Resource Sharing) Misconfigurations Reference

## Attack Surface Signals
- API endpoints returning private user data, tokens, PII, or internal metrics.
- Responses containing `Access-Control-Allow-Origin` (ACAO), `Access-Control-Allow-Credentials` (ACAC).
- Requests supporting custom `Origin` header reflection.

## Flaw Patterns & Bypasses
1. **Arbitrary Origin Reflection with Credentials**:
   - Request: `Origin: https://attacker.com`
   - Response: `Access-Control-Allow-Origin: https://attacker.com` AND `Access-Control-Allow-Credentials: true`.
   - Result: Attacker website can read response body via standard `fetch(url, {credentials: "include"})`.
2. **Null Origin Trust (`Origin: null`)**:
   - Response: `Access-Control-Allow-Origin: null` AND `Access-Control-Allow-Credentials: true`.
   - Triggerable via sandboxed iframes: `<iframe sandbox="allow-scripts allow-top-navigation allow-forms" src="...">`.
3. **Flawed Regex Prefix / Suffix / Subdomain Matching**:
   - Prefix match: `Origin: https://victim.com.attacker.com`
   - Suffix / unescaped dot match: `Origin: https://notvictim.com` or `Origin: https://victimxcom.com`.
   - Unvalidated subdomains: `Origin: https://vulnerable-subdomain.victim.com` (chains with XSS or subdomain takeover).
4. **Internal Network / Localhost Trust**:
   - `Origin: http://localhost`, `Origin: http://127.0.0.1`, `Origin: http://local.victim.com`.
5. **Preflight Cache Poisoning**:
   - Overly broad `Access-Control-Max-Age` caching permissive CORS headers.

## Exploit Chains
- **CORS Misconfiguration → PII / API Key Theft**: Stealing authentication tokens, private messages, or billing details when victim visits attacker page.
- **CORS + Subdomain Takeover → Session / Data Compromise**: Trusting wildcard subdomains allows compromised subdomain to read data from root domain.
