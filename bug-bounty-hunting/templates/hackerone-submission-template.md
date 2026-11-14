# HackerOne Submission Template

Use this template structure when preparing reports for HackerOne submission.

## File Structure
```
target-name-vuln-type/
├── REPORT_SUBMIT.md              # Full report (reference)
├── vulnerability-description.md  # → copy to "Description" field
├── impact-description.md         # → copy to "Impact" field
├── poc-script.sh                 # → attach to report
├── 01-evidence-name.html         # → attach to report (code evidence)
├── 02-evidence-name.html         # → attach to report (more evidence)
└── target-name-vuln.zip          # → all files bundled
```

## vulnerability-description.md Template
```markdown
## Summary
[1-2 sentence description of the vulnerability]

## Vulnerability Details
[Detailed technical explanation]

## Affected Component
- File: [filepath]
- Line: [line number]
- Function: [function name]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Proof of Concept
[Include PoC script content or curl commands]

## Code Evidence
[Reference attached HTML files]
```

## impact-description.md Template
```markdown
## Impact
[What an attacker could achieve]

## Affected Users
[Scope of impact — all users, admin only, etc.]

## Attack Prerequisites
[What access/knowledge is needed]

## Potential Damage
- [Damage 1]
- [Damage 2]

## CVSS Vector
CVSS:3.0/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N
```

## CVSS Quick Reference
- **SSRF (VIEW access):** `CVSS:3.0/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N` = 7.1 High
- **SSRF (Admin access):** `CVSS:3.0/AV:N/AC:L/PR:H/UI:N/S:C/C:H/I:N/A:N` = 6.5 Medium
- **SSRF (Author+ role):** `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:L/A:N` = 5.4 Medium
- **Stored XSS:** `CVSS:3.0/AV:N/AC:L/PR:L/UI:R/S:C/C:L/I:L/A:N` = 5.4 Medium
- **IDOR:** `CVSS:3.0/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N` = 6.5 Medium
- **RCE (blog token):** `CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H` = 9.8 Critical
- **RCE (user input):** `CVSS:3.0/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` = 9.9 Critical
```
