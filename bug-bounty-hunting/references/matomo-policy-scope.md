# Matomo HackerOne Policy & Scope

Last verified: 2026-05-13

## In-Scope Assets (Bounty Eligible)

| Asset | Type | Max Severity | Bounty |
|-------|------|-------------|--------|
| matomo.cloud | URL | Critical | 💰 |
| github.com/matomo-org/docker | URL | Critical | 💰 |
| github.com/matomo-org/matomo | SOURCE_CODE | Critical | 💰 |
| plugins.matomo.org/developer/matomo-org | SOURCE_CODE | Critical | 💰 |
| plugins.matomo.org/developer/innocraft | SOURCE_CODE | Critical | 💰 |
| github.com/matomo-org | SOURCE_CODE | High | 💰 |
| github.com/innocraft/ | SOURCE_CODE | High | 💰 |
| org.piwik.mobile2 | GOOGLE_PLAY_APP_ID | Medium | ❌ |
| 737216887 | APPLE_STORE_APP_ID | Medium | ❌ |
| api.matomo.org | URL | None | ❌ |
| matomo.org | URL | None | ❌ |
| forum.matomo.org | URL | None | ❌ |
| shop.matomo.org | URL | None | ❌ |
| plugins.matomo.org | URL | None | ❌ |

## Bounty Ranges

- **Critical** (RCE/SQLi without auth): up to **$13,000 USD**
- **High** (XSS/CSRF/Auth bypass): up to **$1,777 USD**
- **Other**: ~**$777 USD** (depending on impact)

## Out-of-Scope Vulnerabilities (CRITICAL — READ BEFORE SUBMITTING)

The following are explicitly excluded:

- **Blind Server-Side Request Forgery (SSRF)** — SSRF was rejected for this reason
- Code vulnerabilities that are not exploitable in a real-world environment
- Theoretical issues or issues based only on code patterns without a working exploit
- Output from automated scans or AI-generated reports that have not been manually verified
- Path disclosure
- Clickjacking
- Cross-Window Forgery (CWF)
- Information disclosure without sensitive impact
- Version disclosure
- The token_auth acts as the user's password (by design)
- Open Directory Listing
- CORS related issues in *.matomo.org websites
- Application Errors on pages
- CRIME/BEAST attack and lack of HTTP security headers
- Security issues as a result of running without HTTPS
- Brute force, DoS, DDoS, phishing, text injection, social engineering
- Missing cookie flags on non-sensitive cookies
- Users with super user privileges can post arbitrary JavaScript
- Vulnerabilities affecting users of outdated browsers/platforms
- Race conditions to bypass limits/quotas
- HSTS or CSP headers
- SPF or DMARC records missing
- Vulnerabilities due to outdated infrastructure
- Vulnerabilities caused by not applying Matomo security best practices
- Vulnerabilities in third-party plugins (not authored by Matomo or InnoCraft)
- CLI is out of scope (including Matomo console commands)

## Reporting Requirements (MUST FOLLOW)

1. Validated in a real, running Matomo instance — NOT just code analysis
2. Working Proof of Concept (payload, request, script, or screenshot/video)
3. Clear description of the vulnerability
4. Affected asset, component, or plugin
5. Required authentication level
6. Step-by-step reproduction instructions
7. Real-world impact explanation

## Signal Requirement

- Level: Strict (>= 1.0)
- Trial reports: 4 per program (new hacker)

## Lessons Learned

### SSRF Report Rejected (2026-05-13)
- Report: #3729822
- Status: Not Applicable (closed)
- Reason: Blind SSRF is explicitly out of scope
- Lesson: Always check the full policy BEFORE investing audit time

### Annotations XSS Submitted (2026-05-13)
- Finding: Stored XSS via annotation.note|raw in Twig template
- Privilege: VIEW access
- Status: Submitted, awaiting response
