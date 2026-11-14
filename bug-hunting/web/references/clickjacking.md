# Clickjacking (UI Redressing) Reference

## Attack Surface Signals
- Sensitive single-click state-changing actions: "Delete Account", "Transfer Funds", "Make Repo Public", "Authorize App", "Allow Camera".
- Pages missing `X-Frame-Options` and `Content-Security-Policy: frame-ancestors`.

## Testing Methodology
1. **Frameability Verification**:
   - Create local HTML POC:
     ```html
     <!DOCTYPE html>
     <html>
     <head><title>Clickjacking POC</title></head>
     <body>
       <h2>Clickjacking Test</h2>
       <iframe src="https://target.com/sensitive-action" width="800" height="600"></iframe>
     </body>
     </html>
     ```
   - Open POC in browser. If target renders inside iframe, target is frameable.
2. **Header Evaluation**:
   - Missing `X-Frame-Options: DENY` or `SAMEORIGIN`.
   - Missing `Content-Security-Policy: frame-ancestors 'none'` or `'self'`.
3. **Frame-Busting Script Bypasses**:
   - Sandboxed iframe disabling frame-busting navigation:
     `<iframe src="..." sandbox="allow-forms allow-scripts">`

## Exploit Chains
- **Clickjacking → Unintended State Execution**: Overlaying transparent iframe over deceptive UI game/button to trick authenticated user into clicking sensitive button.
