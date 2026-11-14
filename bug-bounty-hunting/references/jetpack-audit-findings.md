# Jetpack/WordPress SSRF Audit Findings (2026-05-12)

## Reports Submitted

### 1. Jetpack Forms Post-to-URL SSRF (CVSS 8.6, auto-adjusted to 5.7)
- **File:** `projects/packages/forms/src/service/class-post-to-url.php:148-164`
- **Issue:** Uses `wp_remote_post()` (unsafe), no URL validation, SSL disabled
- **Evidence:** TODO comment at line 82: "eventually, I'd like us to verify the URL"
- **Trigger:** Contributor+ creates post with `salesforceData` + `postToUrl` attributes
- **Bypass:** Legacy `Post_To_Url` still active despite newer `Form_Webhooks` having protection

### 2. Jetpack External Media SSRF (CVSS 5.4)
- **File:** `class-wpcom-rest-api-v2-endpoint-external-media.php:740-751`
- **Issue:** `download_url()` accepts ANY URL, no domain allowlist
- **Trigger:** Author+ calls `POST /wp-json/wpcom/v2/external-media/copy/{service}`
- **Bypass:** `wp_safe_remote_get()` validates initial URL but follows 302 redirects without re-validation

## Other Findings (Not Submitted)

### 3. Backup Helper Script RCE (CVSS 9.8, Critical) ✅ SUBMITTED
- **File:** `class-jetpack-json-api-install-backup-helper-script-endpoint.php`
- **Issue:** `$needed_capabilities = array()` — NO capabilities required, accepts base64 PHP
- **Trigger:** Blog token auth only (`allow_jetpack_site_auth => true`)
- **Impact:** Full RCE — base64 PHP written to web-accessible `jetpack-temp/` directory, URL returned in response
- **Bypass:** Blog token bypasses ALL capability checks (`check_capability()` returns `true` immediately)
- **Key code:** `base64_decode($args['helper'])` → `file_put_contents($file_path, $script_body)`
- **Persistence:** Scripts persist 8 hours (28800s) before cleanup
- **Note:** CVSS 9.8 but bounty may be lower because blog token is prerequisite. Report focuses on defense-in-depth failure.
- **HackerOne:** https://hackerone.com/reports/3730157

### Unauthenticated Endpoints
- `jetpack/v4/remote_authorize` — processes authorization secrets
- `jetpack/v4/verify_registration` — site registration
- `jetpack/v4/sync/spawn-sync` — triggers sync without auth

### Themes Install unserialize
- **File:** `class.jetpack-json-api-themes-install-endpoint.php:170`
- **Issue:** `unserialize()` on HTTP response from api.wordpress.org

### Forms Webhooks DNS Rebinding
- **File:** `class-form-webhooks.php:262-326`
- **Issue:** TOCTOU race — hostname resolved during validation, different DNS at request time

## Key Technique: WordPress Redirect Bypass
`download_url()` → `wp_safe_remote_get()` → validates INITIAL URL only.
Attack: public server returns 302 to `http://169.254.169.254/latest/meta-data/`
The redirect target is NOT re-validated = SSRF achieved.
