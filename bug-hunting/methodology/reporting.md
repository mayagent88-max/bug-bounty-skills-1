---
name: bug-hunting-reporting
description: How to validate a finding and write it up so it gets paid -- evidence capture, triage-proofing, report structure.
---

# Vulnerability Validation & Report Writing Guide

A valid vulnerability report is a technical document demonstrating concrete, unauthorized security impact on an in-scope asset. Programs pay for clear impact, reliable reproduction, and professional evidence hygiene.

---

## 1. Finding Validation Gate (Pre-Report Checklist)

Before drafting any report, verify each item:

- [ ] **In-Scope Asset**: Is the hostname/endpoint explicitly within program scope?
- [ ] **Reproduced Twice**: Have you verified the issue from a fresh, clean browser session or clean terminal context?
- [ ] **Demonstrated Real Impact**: Is there actual data loss, account takeover, code execution, or financial disruption (not just a scanner flag or theoretical missing header)?
- [ ] **Minimal Exploitation**: Did you stop immediately upon proving impact without altering production data or accessing other customers' PII unnecessarily?
- [ ] **Attributed Root Cause**: Do you understand *why* the vulnerability occurs (e.g. missing object check vs parser differential)?

---

## 2. Standard Triage-Proof Report Template

```markdown
# [Vulnerability Type] in [Endpoint/Component] leading to [Concrete Impact]

## Summary
A brief 2-3 sentence executive summary explaining the vulnerability, the vulnerable endpoint, and the maximum security impact.

## Target Details
- Vulnerable URL: `https://target.com/api/v1/user/profile`
- HTTP Method: `PUT`
- Affected Parameter: `user_id` / `email`
- User Roles Required: Low-privileged Authenticated User (Account B)

## Step-by-Step Reproduction
1. Log in to Account A (`victim@target.com`) in Browser 1 and note the user ID (`12345`).
2. Log in to Account B (`attacker@evil.com`) in Browser 2.
3. In Browser 2, intercept the profile update request and modify the `user_id` parameter to `12345`:
   \`\`\`http
   PUT /api/v1/user/profile HTTP/1.1
   Host: target.com
   Authorization: Bearer <Account_B_Token>
   Content-Type: application/json

   {
     "user_id": 12345,
     "email": "attacker@evil.com"
   }
   \`\`\`
4. Observe the response: HTTP 200 OK with `{"status": "success", "email": "attacker@evil.com"}`.
5. In Browser 1, refresh Account A profile to confirm email has been overwritten without authorization.

## Proof of Concept (Evidence)
- Attach complete raw HTTP request & response logs.
- Embed clear screenshots or unedited video POC if reproduction requires complex UI interaction.
- Provide curl command with sanitized tokens.

## Business Impact & Severity Evaluation
- **Severity**: High (CVSS 8.5)
- **Impact**: Any authenticated attacker can modify any customer's registered email address, triggering password resets to take over arbitrary accounts.

## Remediation Recommendation
Enforce server-side authorization checks verifying that the authenticated session owns the target `user_id` before executing database updates.
```

---

## 3. Triage Kill-List (What Gets Closed as N/A / Informative)

| Finding Type | Why It Gets Closed | How to Fix Before Submitting |
|---|---|---|
| **Missing Security Headers** | No demonstrable impact on modern browsers | Chain with a real clickjacking POC or CSRF proof |
| **Self-XSS / Console XSS** | Requires victim to paste code in DevTools | Chain with CSRF, login reflection, or OAuth flow |
| **Blind SSRF Without OOB** | Time delays alone are unreliable proof | Provide DNS/HTTP interactsh logs demonstrating callback |
| **Open Redirect to Same Domain** | No cross-domain phishing or token leakage | Chain with OAuth `redirect_uri` or external domain |
| **Theoretical Rate Limiting** | Automated scanners flagging missing 429 | Prove actual state damage (e.g. 500 reset emails delivered) |
| **Software Version Disclosure** | Banners alone (`Server: Apache 2.4.41`) | Demonstrate working exploit for that specific version |
