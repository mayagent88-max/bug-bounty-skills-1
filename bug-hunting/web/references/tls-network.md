# TLS & Network Infrastructure Reference

## Attack Surface Signals
- Network perimeter, SSL/TLS handshake configurations, DNS records, Mail exchangers (MX), SPF/DMARC records.

## Assessment Techniques
1. **Dangling DNS Records (Subdomain Takeovers)**:
   - High-value finding: CNAME record pointing to de-provisioned SaaS host (S3, CloudFront, Azure App Service, Heroku).
2. **TLS / SSL Misconfigurations**:
   - Insecure protocols: SSLv3, TLS 1.0, TLS 1.1 enabled.
   - Weak ciphers: RC4, 3DES, EXPORT, NULL ciphers.
   - Missing HSTS (`Strict-Transport-Security: max-age=...; includeSubDomains; preload`).
3. **Email Security Configuration**:
   - SPF record missing or ending in `+all` / `?all`.
   - DMARC policy set to `p=none` or missing entirely (allows direct domain email spoofing).
4. **DNS Zone Transfer (AXFR)**:
   - `dig AXFR @ns1.target.com target.com` (reveals complete internal and external DNS topology if misconfigured).

## Exploit Chains
- **Dangling DNS → Subdomain Takeover → Cross-Domain Session Cookie Theft**.
- **Missing SPF / DMARC Reject Policy → High-Reputation Phishing Attacks**.
