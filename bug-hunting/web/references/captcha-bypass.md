# CAPTCHA Bypass Reference

## Attack Surface Signals
- Login, registration, password reset, feedback forms protected by reCAPTCHA, hCaptcha, Cloudflare Turnstile, or custom image CAPTCHAs.
- Parameters: `g-recaptcha-response`, `h-captcha-response`, `captcha_code`, `captcha_id`.

## Bypass Techniques
1. **Parameter Removal & Null Values**:
   - Completely delete the CAPTCHA response parameter from the request.
   - Submit empty string `g-recaptcha-response=` or `null`.
2. **Response Replay & Token Reusability**:
   - Solve CAPTCHA once to obtain valid token.
   - Replay the same solved token across multiple automated requests.
3. **Server-Side Validation Failure**:
   - Submit arbitrary invalid token string (e.g. `g-recaptcha-response=test1234`).
   - Backend checks if parameter exists but skips verifying token against Google/hCaptcha verification API.
4. **Alternative Endpoint / API Version**:
   - Mobile API (`/api/mobile/login`) or older API version (`/api/v1/login`) lacking CAPTCHA verification.
   - JSON vs Form-URL-Encoded endpoints.
5. **Insecure Direct Audio / OCR Solving**:
   - Audio challenge easily transcribed using automated Speech-to-Text APIs.
   - Static / low-entropy custom CAPTCHAs with predictable image sets or client-side answer disclosure.

## Exploit Chains
- **CAPTCHA Bypass + Credential Stuffing → Mass Account Takeover**: Bypassing bot protection to automate credential testing at scale.
