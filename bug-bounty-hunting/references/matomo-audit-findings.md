# Matomo Audit Findings

Last updated: 2026-05-13

## Program Info
- **Platform**: HackerOne (hackerone.com/matomo)
- **Signal Requirement**: Strict (≥ 1.0)
- **Trial Reports**: 4 per program (new hacker)
- **Repo**: github.com/matomo-org/matomo (PHP, 21.5K stars, 3396 PHP files, 98 plugins)
- **Branch**: 5.x-dev (default)
- **Installed at**: /tmp/bugbounty/matomo/
- **Policy**: See `references/matomo-policy-scope.md` for full out-of-scope list

## Bounty Range
- 🔴 **Critical** (RCE/SQLi without auth): up to **$13,000 USD**
- 🟠 **High** (XSS/CSRF/Auth bypass): up to **$1,777 USD**
- 🟡 **Other**: ~**$777 USD**

## Finding 1: SSRF via SiteContentDetector — ❌ REJECTED

### Summary
The `http.blocklist.hosts` config only blocks `*.amazonaws.com`. Internal/private IPs are not blocked. The `SiteContentDetector` fetches the configured site URL without proper SSRF protection.

### Status: REJECTED (Not Applicable)
- **Report:** #3729822
- **Reason:** "As mentioned in the pre-submission hook, this is out of scope"
- **Why:** Blind SSRF is explicitly excluded in Matomo's HackerOne policy
- **Lesson:** Always check program policy BEFORE investing audit time

### Vulnerable Code Paths (for reference only)
1. **Weak blocklist**: `config/global.php:255` — only `*.amazonaws.com`
2. **No URL validation**: `plugins/SitesManager/API.php:754` — `addSite()` doesn't validate URLs
3. **SSRF trigger (VIEW access)**: `plugins/SitesManager/API.php:2092` — `detectConsentManager()` only needs VIEW access
4. **Server fetches URL**: `core/SiteContentDetector.php:343` — `requestSiteResponse()` fetches site URL

---

## Finding 2: Stored XSS via Annotation Notes — ✅ SUBMITTED

### Summary
The `filterNote()` method in `plugins/Annotations/API.php` performs only length truncation (255 characters) without HTML sanitization. The annotation notes are rendered in `_annotation.twig` using the `|raw` Twig filter, which bypasses auto-escaping, allowing arbitrary HTML/JavaScript execution.

### Status: Submitted, awaiting response

### Vulnerable Code Paths
1. **No HTML sanitization**: `plugins/Annotations/API.php:324` — `filterNote()` only truncates length
2. **Unsafe template rendering**: `plugins/Annotations/templates/_annotation.twig:32` — `{{ annotation.note|raw }}`
3. **Unsafe input value**: `plugins/Annotations/templates/_annotation.twig:39` — `value="{{ annotation.note|raw }}"`
4. **Contrast (proper escaping)**: `plugins/Annotations/templates/getEvolutionIcons.twig:8` — `counts.note|e('html_attr')`

### CVSS
`CVSS:3.1/AV:N/AC:L/PR:L/UI:R/S:C/C:L/I:L/A:N` = **5.4 (Medium)**

### Attack Vector
- **Privilege Required:** VIEW access (not anonymous, not admin)
- **Payload:** `<img src=x onerror=alert(document.cookie)>`
- **Impact:** XSS executes in browser of ALL users viewing annotations, including Super User
- **Persistence:** Stored in database, executes every time annotation is viewed

### Report Files
- `/tmp/bugbounty/matomo-annotations-xss/REPORT_SUBMIT.md` — Full report
- `/tmp/bugbounty/matomo-annotations-xss/vulnerability-description.md` — For "Description" field
- `/tmp/bugbounty/matomo-annotations-xss/impact-description.md` — For "Impact" field
- `/tmp/bugbounty/matomo-annotations-xss/poc-annotation-xss.sh` — PoC script
- `/tmp/bugbounty/matomo-annotations-xss/01-filterNote-no-sanitization.html` — Code evidence
- `/tmp/bugbounty/matomo-annotations-xss/02-template-raw-filter.html` — Code evidence
- `/tmp/bugbounty/matomo-annotations-xss/03-data-flow-analysis.html` — Code evidence
- `/tmp/bugbounty/matomo-annotations-xss/hackerone-submission-fields.md` — Copy-paste form fields
- `/tmp/bugbounty/matomo-annotations-xss/severity-breakdown.md` — CVSS button selections

---

## Other Findings (Not Submitted)

### Information Disclosure (Low, ~$250)
- `InvalidRequestParameterException::__toString()` leaks file path + line number
- Trigger: Send invalid parameter to tracking API
- File: `core/Exception/InvalidRequestParameterException.php:16`

### Confirmed NOT Exploitable
### Confirmed NOT Exploitable (Updated 2026-05-13)
- **Stored XSS via Annotations**: `decorateAnnotation()` calls `Common::sanitizeInputValue()` on OUTPUT which runs `htmlspecialchars()`. The `|raw` in template is irrelevant because data is pre-escaped. Report rejected by Matomo staff — "XSS is never executed, annotation remains escaped in the UI."
- **XSS via Custom Dimensions**: Name validated with `strip_tags()` + blocked chars `<`, `>`, `/`, `\\`, `&`, `.`
- **XSS via rawSafeDecoded**: Uses `htmlspecialchars()` internally, safe for HTML context
- **Deserialization**: `safe_unserialize()` blocks all classes (`allowed_classes => false`)
- **SQL Injection**: 100% parameterized queries (`?` bind)
- **Command Injection**: All `exec()`/`shell_exec()` in CLI commands only, not web-accessible
- **Open Redirect (logme)**: Redirect validated against `trusted_hosts`, disabled by default

### Lesson Learned: Always Check Output Encoding
The Annotations XSS analysis failed because it only checked INPUT (`filterNote()`) without checking OUTPUT (`decorateAnnotation()` → `Common::sanitizeInputValue()` → `htmlspecialchars()`). When auditing XSS, trace the COMPLETE data flow: input → storage → output. The `|raw` Twig filter is only dangerous if the data is NOT pre-escaped before reaching the template.

## Key Defense Patterns in Matomo
1. `Common::safe_unserialize()` — blocks all classes by default
2. Parameterized SQL queries everywhere
3. `strip_tags()` + character blocklist for user input names
4. `Url::isValidHost()` for redirect validation
5. `http.blocklist.hosts` for SSRF (but minimal — only AWS)
6. `checkUserHasViewAccess()` / `checkUserHasAdminAccess()` for auth

## Key Audit Technique: Twig `|raw` Contrast
When auditing Twig templates, look for `|raw` usage. If the SAME plugin has some templates using `|raw` and others using `|e('html_attr')`, the `|raw` instances are likely bugs. This was the key evidence for the Annotations XSS finding.
