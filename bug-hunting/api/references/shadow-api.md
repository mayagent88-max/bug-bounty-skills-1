# Shadow & Zombie APIs Reference

## Attack Surface Signals
- **Version Discrepancies**: `/api/v1/`, `/api/v2/`, `/api/v3/`, `/api/v1.1/`, `/api/beta/`, `/api/internal/`, `/api/legacy/`.
- **Exposed Unlinked Documentation**: `/v1/swagger.json`, `/v2/api-docs`, `/openapi.json`, `/api-docs/v1`, `/doc/v1/spec.yaml`.
- **Subdomain Clones**: `api-dev.target.com`, `api-staging.target.com`, `api-legacy.target.com`, `old-api.target.com`.

## Discovery & Version Enumeration
1. **Systematic Route Version Brute-Forcing**:
   - Use `ffuf` to enumerate version prefixes against known endpoints:
     `ffuf -u https://target.com/api/FUZZ/users -w versions.txt` (Wordlist: `v1`, `v2`, `v3`, `v0`, `beta`, `dev`, `staging`, `internal`, `legacy`, `old`, `test`).
2. **Swagger / OpenAPI Spec Hunting**:
   - Probe for unlinked version specs:
     - `/swagger/v1/swagger.json` vs `/swagger/v2/swagger.json` vs `/swagger/internal/swagger.json`
     - `/api/openapi.json` vs `/api/v1/openapi.json`
3. **Client-Side JS Route Extraction**:
   - Extract regex matches for deprecated routes from legacy JS bundles:
     `grep -Eo '["\']/(api/v[0-9]+/[a-zA-Z0-9_/]+)["\']' app.js`

## Behavioral Differentials & Attack Patterns
1. **Security Control Regressions**:
   - Check if deprecated version (`/api/v1/`) lacks newer security controls:
     - Missing rate limiting / brute-force protection (e.g. `/api/v1/login` allows unlimited attempts while `/api/v2/login` enforces 429).
     - Missing Multi-Factor Authentication (MFA) enforcement.
     - Missing Bot protection / CAPTCHA checks.
     - Relaxed input validation (SQLi / XSS patched in v2 but still vulnerable in v1).
2. **Zombie Endpoint Resuscitation**:
   - Test endpoints deprecated from the frontend UI that still execute backend mutations:
     - `/api/v1/users/export_all`
     - `/api/v1/admin/impersonate`
     - `/api/v1/coupon/apply_legacy`
3. **Mass Assignment in Unmaintained Schemas**:
   - Older API schemas frequently bind raw request payloads directly to database entities without modern DTO filters:
     - POST `/api/v1/user/update` with `{"role": "admin", "is_verified": true}`.

## Exploit Chains
- **Shadow v1 Route → Missing MFA & Rate Limit → Credential Stuffing & ATO**.
- **Deprecated Endpoint → Unpatched SQLi / Mass Assignment → Remote Database Takeover**.
