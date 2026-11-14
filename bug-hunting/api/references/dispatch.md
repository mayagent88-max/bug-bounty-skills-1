# Dynamic Routing & 404 Baseline Reference

## Attack Surface Signals
- Complex frontend routing architectures: Next.js / Nuxt catch-all routes (`[...slug].js`), micro-frontends, reverse proxy rewrites, API gateways (Kong, Apigee, AWS API Gateway, Traefik).
- Catch-all fallback handlers, dynamic controller dispatchers, vanity URL systems (`/company-name`, `/{username}`).

## Step 0: Mandatory 404 Baseline Protocol
Before performing any route enumeration, establish the precise 404 baseline behavior:
1. **Baseline Invocations**:
   - Request 3 non-existent random paths:
     `GET /404_canary_abc123_test`
     `GET /api/404_canary_xyz890_test`
     `POST /404_canary_post_test` with `{"test": true}`
2. **Record Baseline Metrics**:
   - HTTP Status Code (e.g. `404`, `200` with soft-404, `302` redirect to home).
   - Response Content-Length (exact byte count).
   - Word count and line count.
   - Specific response body signature / JSON structure (e.g. `{"error": "Route not found"}`).
3. **Differential Filters for Fuzzing**:
   - Filter out baseline false positives in `ffuf`:
     `ffuf -u https://target.com/FUZZ -w routes.txt -fs <baseline_size> -fc 404`

## Dynamic Dispatch & Route Confusion Patterns
1. **Catch-All Handler Misconfigurations**:
   - Frontend server intercepts request and returns 200 OK SPA HTML page for all routes, masking backend 404/403 states.
   - Identify backend API bypasses by forcing API headers:
     `Accept: application/json`, `X-Requested-With: XMLHttpRequest`.
2. **Reverse Proxy Path Desynchronization**:
   - Gateway strips trailing slash or merges slashes: `/api//admin` vs `/api/admin`.
   - Matrix URL parameters: `/app/..;/admin`, `/api;version=1/internal`.
3. **Vanity URL Collision**:
   - Inject system-reserved names into vanity slug registration:
     - Register username: `admin`, `api`, `static`, `assets`, `login`, `oauth`, `settings`.
   - Causes routing conflict where user-controlled content overrides system routing logic.

## Exploit Chains
- **Route Confusion → Reverse Proxy Auth Filter Bypass → Access Internal Management APIs**.
- **Vanity Slug Registration Collision → System Route Hijacking & Account Phishing**.
