# Laravel Hunting Reference

## Attack Surface Signals
- Cookies: `laravel_session`, `XSRF-TOKEN` (base64 serialized payload).
- Stack traces mentioning `Illuminate\`, `vendor/laravel/framework`.
- Debug pages: Ignition error pages (`flare.spatie.be`, `Whoops! There was an error`).

## Key Attack Vectors
1. **Ignition Debug Mode RCE (CVE-2021-3129)**:
   - Endpoint: `POST /_ignition/execute-solution`
   - Unauthenticated RCE via `facade-solutions` and PHP wrapper manipulation.
2. **Exposed `.env` / `APP_KEY` Leakage**:
   - `APP_KEY` (base64 string in `.env`) allows decrypting and forging `laravel_session` cookies.
   - Forge serialized cookie with `PHPGGC` gadget chain (e.g. `Laravel/RCE9`) to achieve pre-auth RCE.
3. **Telescope & Horizon Dashboard Exposure**:
   - `/telescope` (logs all requests, auth tokens, database queries, headers).
   - `/horizon` (Redis queue manager, job replay).
4. **Signed URL Tampering**:
   - Endpoints using `URL::signedRoute()`: verify if signature validates all query parameters or can be stripped.
5. **Mass Assignment in Eloquent Models**:
   - Unprotected `$guarded` or overly permissive `$fillable` allowing `{"is_admin": true}` in profile update.

## Exploit Chains
- **Exposed APP_KEY / Ignition Debugger → Pre-Auth Remote Code Execution**.
