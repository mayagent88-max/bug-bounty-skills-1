# Node.js & Express Hunting Reference

## Attack Surface Signals
- Header: `X-Powered-By: Express`.
- JSON-heavy REST APIs, asynchronous JavaScript event-loop behaviors.

## Core Attack Techniques
1. **Server-Side Prototype Pollution**:
   - Sinks: `lodash.merge`, `lodash.defaultsDeep`, recursive object cloning, `qs` query parser.
   - Payloads: `{"__proto__": {"NODE_OPTIONS": "--inspect"}}`, `{"constructor": {"prototype": {"isAdmin": true}}}`.
   - RCE Gadgets: Polluting `child_process.fork()` options, `shell`, `execPath`, or template compiler properties.
2. **Template Injection (SSTI)**:
   - Engines: EJS (`<%- process.mainModule.require('child_process').execSync('id') %>`), Pug, Handlebars, Nunjucks.
3. **Command Injection via `child_process`**:
   - `child_process.exec()` vulnerable to shell metacharacters (`;`, `&&`, `` ` ``).
4. **Express `trust proxy` Misconfiguration**:
   - Bypassing IP-based rate limiting or authorization via client-supplied `X-Forwarded-For` when `trust proxy` is enabled globally.

## Exploit Chains
- **Prototype Pollution → Gadget Execution → Remote Code Execution**.
