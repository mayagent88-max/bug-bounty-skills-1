# SPA Backend & Unpacked Client API Reference

## Attack Surface Signals
- Single Page Applications built with React, Vue, Angular, Svelte, Next.js, Nuxt.
- Large compiled JavaScript bundles: `app.min.js`, `chunk-vendors.js`, `main.js`, `bundle.js`.
- Source maps: `.js.map` files reachable alongside `.js` files.

## Extraction & Reconnaissance Methodology
1. **Source Map Recovery**:
   - Check if source maps are exposed:
     `curl -s https://target.com/static/js/main.12345.js | grep -o 'sourceMappingURL=.*'`
   - Reconstruct original project source tree using `sourcemapper` or `unwebpack-sourcemap`:
     `unwebpack-sourcemap -d ./unpacked https://target.com/static/js/main.js.map`
2. **Regex-Based Endpoint & Secret Scraping**:
   - Scrape all API paths and route definitions:
     `grep -Eo '["\']/(api|v1|v2|internal|admin)/[a-zA-Z0-9_/-]+["\']' bundle.js`
   - Scrape hardcoded secrets and environment tokens:
     `grep -Eo '(AKIA[0-9A-Z]{16}|bearer [a-zA-Z0-9_.-]+|ghp_[a-zA-Z0-9]+|eyJ[a-zA-Z0-9_-]{10,})' bundle.js`
3. **Hidden Feature Flags & Role Gates**:
   - Inspect client-side permission checks: `if (user.role === 'admin')`, `isFeatureEnabled('beta_billing')`.
   - Find disabled or unlinked UI components that reference active backend APIs.

## Testing Exposed Unlinked Endpoints
1. **Direct API Replay**:
   - Test discovered `/api/internal/*`, `/api/admin/*`, `/api/export/*` endpoints directly with standard user tokens or unauthenticated via curl.
2. **Client-Side Auth vs Backend Auth**:
   - Many SPAs only hide buttons/tabs in the frontend for non-admin users while backend API routes lack server-side role validation.

## Exploit Chains
- **Source Map Leak → Unlinked Admin API Discovery → Missing Server-Side Role Check → Full Admin Escalation**.
- **Hardcoded Developer API Key in JS Bundle → Third-Party Service (SendGrid/AWS) Takeover**.
