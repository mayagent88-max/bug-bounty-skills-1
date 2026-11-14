# DOM-Based Vulnerabilities & Clobbering Reference

## Attack Surface Signals
- Sources: `location.hash`, `location.search`, `document.referrer`, `window.name`, `localStorage`, `postMessage`.
- Sinks: `innerHTML`, `outerHTML`, `document.write`, `eval`, `setTimeout`, `location.href`, `script.src`.

## Attack Patterns & Techniques
1. **DOM-Based XSS**:
   - Trace flow from source (e.g. `location.hash`) to sink (e.g. `document.getElementById('content').innerHTML = hash`).
2. **DOM Clobbering**:
   - Inject HTML elements with `id` or `name` to overwrite global JavaScript variables or window properties.
   - Single-element clobber: `<a id="config" href="javascript:alert(1)">` -> overwrites `window.config`.
   - Multi-element collection: `<a id="x" name="y" href="1"></a><a id="x" name="y" href="2"></a>` -> creates `window.x.y`.
   - Form-element clobber: `<form id="user"><input name="avatar" value="evil.jpg"></form>`.
3. **Cross-Window / PostMessage Insecurities**:
   - Missing origin verification in listener: `window.addEventListener('message', (e) => { ... })` without checking `e.origin`.
   - Insecure data handling: Passing `e.data` directly into `eval` or DOM sinks.
4. **Client-Side Prototype Pollution**:
   - Sinks: `Object.assign()`, recursive merge, query string parsers (`qs`, `lodash.merge`).
   - Payloads: `?__proto__[src]=evil.js`, `?constructor.prototype.polluted=true`.
   - Chain prototype pollution gadgets to trigger DOM XSS or override security checks.

## Exploit Chains
- **DOM Clobbering / Prototype Pollution → DOM XSS → Account Takeover**.
