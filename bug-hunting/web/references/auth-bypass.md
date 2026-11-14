# Authentication & Access Control Bypass Reference

## Attack Surface Signals
- Unauthenticated access to admin panels, internal APIs, or debugging endpoints.
- Path parameters controlling access levels: `/admin`, `/api/internal`, `/management`, `/private`.
- Header-based routing: Reverse proxies, API gateways, load balancers stripping/adding auth headers.
- Multi-factor authentication, SSO callbacks, password reset endpoints.

## Bypass Techniques & Detection Patterns
1. **Path Normalization & URL Parsing Differentials**:
   - URL encoding / double encoding: `/%2e%2e/admin`, `/admin%2f`, `/admin%00`.
   - Traversal in path: `/static/..;/admin`, `/public/../admin`, `/app/.;/admin`.
   - Semicolon / Matrix parameters: `/admin;param=1/dashboard`, `/admin;foo/bar` (Spring / Tomcat).
   - Case sensitivity & extensions: `/ADMIN`, `/Admin.json`, `/admin.php`, `/admin.action`.
2. **Header-Based Trust Spoofing**:
   - `X-Forwarded-For: 127.0.0.1`, `X-Original-URL: /admin`, `X-Rewrite-URL: /admin`
   - `X-Custom-IP-Authorization: 127.0.0.1`, `Client-IP: 127.0.0.1`, `X-Real-IP: 127.0.0.1`
   - `X-Forwarded-Host: localhost`, `X-Host: localhost`
3. **HTTP Verb & Method Overriding**:
   - Send `HEAD`, `OPTIONS`, `TRACK`, `DEBUG`, or `PURGE`.
   - Method override headers: `X-HTTP-Method-Override: GET`, `X-Method-Override: PUT`.
   - Query param override: `?_method=GET`, `?_http_method=POST`.
4. **Content-Type / Parser Confusion**:
   - Send empty body with `Content-Length: 0`.
   - Switch `Content-Type: application/json` to `application/xml` or `text/plain`.
   - JSON parsing anomalies: `{"role":"user","role":"admin"}`.

## Common Root Causes
- Middleware/WAF parses URL differently than the backend application framework (e.g. Nginx regex vs Spring Web path matching).
- Function-level access control (FLAC) missing on administrative controllers.
- Implicit trust in headers injected or manipulated by clients when reverse proxy lacks sanitization.

## Exploit Chains
- **Auth Bypass → RCE**: Bypassing gateway auth on `/actuator`, `/debug/pprof`, or administrative console endpoints.
- **Auth Bypass → Privilege Escalation**: Reaching internal user-management API to assign tenant administrator privileges.
