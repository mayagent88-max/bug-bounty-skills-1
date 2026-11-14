# Next.js Hunting Reference

## Attack Surface Signals
- HTML headers/scripts containing `__NEXT_DATA__`, `/_next/static/`, `/_next/image`, `x-powered-by: Next.js`.
- React Server Components (RSC) and Server Actions (`Next-Action` header).

## Core Attack Surfaces
1. **Server Actions Exploitation**:
   - Unauthenticated Server Action IDs invoked via POST with `Next-Action: <hash>` header.
   - Missing authorization checks inside server action closures.
2. **Next.js Middleware Auth Bypass**:
   - Middleware URL matching regex discrepancies (e.g. `/_next/data/`, trailing slash `/admin/`, case sensitivity).
3. **Image Optimization SSRF (`/_next/image`)**:
   - `/_next/image?url=http://169.254.169.254/latest/meta-data/&w=64&q=75`
   - Check if remote domains in `images.remotePatterns` are overly permissive (e.g. wildcard subdomains).
4. **`__NEXT_DATA__` & `/_next/data/` IDOR / Secret Leaks**:
   - Inspect JSON in `<script id="__NEXT_DATA__">` for unredacted backend state, database records, API keys.
5. **ISR / SSR Cache Poisoning**:
   - Poisoning statically generated pages via unkeyed headers in Next.js caching layer.

## Exploit Chains
- **Middleware Path Confusion → Admin Endpoint Bypass**.
- **Next.js Image Handler → Internal SSRF**.
