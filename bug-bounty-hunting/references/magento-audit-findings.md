# Adobe/Magento 2 — Codebase Audit & Attack Surface Analysis (2026-05-13)

## Repo Stats

- GitHub: `magento/magento2` (branch: `2.4-develop`)
- Stars: 12,110 | Forks: 9,373
- Size: 732 MB | Total files: 38,754
- PHP files: 23,549 | XML: 9,671 | PHTML templates: 974
- Modules: ~222 under `app/code/Magento/`
- License: OSL-3.0 (Open Software License)
- Latest release: v2.4.9 (2026-05-12) with parallel patches (2.4.8-p5, 2.4.7-p10, 2.4.6-p15)

## Architecture Overview

- **Modular monolith** — 222 modules, each with own API, controllers, models, templates
- Configuration heavily XML-driven (`webapi.xml`, `di.xml`, `routes.xml`, `acl.xml`)
- `ObjectManager` pattern used in 1,415 files (weak DI, hard to trace data flow)
- 148 third-party packages in `composer.lock` (supply chain risk)
- REST API defined in `webapi.xml` files, GraphQL in `schema.graphqls`

## Unauthenticated Attack Surface (HIGH VALUE)

### REST API — 41 anonymous endpoints including:
- `POST /V1/customers` — create customer account
- `POST /V1/integration/admin/token` — admin token generation (brute force target, no rate limit by default)
- `POST /V1/integration/customer/token` — customer token generation
- `PUT /V1/customers/password` — initiate password reset
- `POST /V1/customers/resetPassword` — reset password
- `POST /V1/customers/isEmailAvailable` — email enumeration
- `POST /V1/guest-carts/:cartId/payment-information` — guest checkout payment
- Various guest cart management endpoints

### GraphQL (all unauthenticated by default):
- `generateCustomerToken`, `createCustomer`, `requestPasswordResetEmail`, `resetPassword`, `createGuestCart`, `placeOrder`
- Full schema exposed via introspection (no auth required)

## Historical Vulnerability Classes

| Class | Count | Notes |
|-------|-------|-------|
| XSS | 63 | Template rendering, WYSIWYG, admin UI |
| SQLi | 16 | Catalog search, filter injection |
| Deserialization | 8 | 15+ files use `unserialize()` |
| RCE | 3 | SSTI in email/CMS templates |
| XXE | 1 | XML import parsers |
| SSRF | 0 (reported) | ProductVideo controller fetches user-supplied URLs |

## High-Value Hunting Areas

### 1. SSRF Vectors
- **ProductVideo** `Controller/Adminhtml/Product/Gallery/RetrieveImage.php` — makes HTTP requests to user-supplied `remote_image` parameter. Uses protocol validator but worth testing.
- **Dashboard Tunnel** `Backend/Controller/Adminhtml/Dashboard/Tunnel.php` — proxies HTTP requests to `Graph::API_URL` with decoded base64 parameters. Hash-protected but uses `base64_decode(urldecode($gaData))`.

### 2. Deserialization Points
- `StoreSwitcher/RedirectDataCacheSerializer.php`
- `AsynchronousOperations/Model/OperationProcessor.php`
- Various cron/schedule models
- 15+ files total with `unserialize()`

### 3. XML Parsing (XXE potential)
- 15+ files use `SimpleXMLElement`/`DOMDocument`
- ImportExport module processes user-uploaded XML

### 4. File Upload (Admin)
- `Product/Gallery/Upload.php`
- `Category/Image/Upload.php`
- `Downloadable/File/Upload.php`
- `MediaGalleryUi/Image/Upload.php`
- Extension allowlists enforced but bypass-worthy

### 5. Store Switcher
- `Store/Controller/Store/SwitchRequest.php` — open redirect with hash validation
- Takes `customer_id`, `time_stamp`, `signature`, encoded URL
- Potential session fixation if hash is weak

### 6. SQL Injection Surface
- CatalogSearch uses `LIKE` queries with user-controlled filter values
- `FilterTypeInput` GraphQL input accepts `like` operator
- Complex ORM with dynamic collection filtering

### 7. Cron System
- `ProcessCronQueueObserver.php` executes cron jobs
- If attacker can inject cron schedules via admin access → code execution

## Security Infrastructure (What's Hardened)

- Dedicated `Magento_Security` module with session management
- `_isAllowed()` authorization checks on admin controllers
- HMAC hash validation on store switcher and dashboard tunnel
- Content Security Policy (`Csp` module)
- CAPTCHA module available
- **No 2FA built-in** (separate `TwoFactorAuth` Adobe Commerce module, not in open source)

## Recurring Vulnerability Patterns

- Pre-auth account takeover via password reset token brute force
- RCE via SSTI in email templates / CMS templates
- XXE in XML import parsers (ImportExport module)
- Admin token brute force (`/V1/integration/admin/token` has no rate limiting by default)
- Mass assignment in customer/account creation APIs
- Open redirect in store switcher and URL rewrite modules
- GraphQL introspection exposing full schema to unauthenticated users
- Stored XSS via product attributes, CMS blocks, newsletter templates
- Payment bypass via cart/checkout API manipulation (price tampering, coupon abuse)

## Best Hunting Strategy

1. **GraphQL mutations** — full schema exposed, unauthenticated, many mutations
2. **Guest checkout flow** — price tampering, coupon abuse, payment manipulation
3. **Admin token endpoint** — brute force (no rate limit default)
4. **File upload bypasses** — product gallery, downloadable files
5. **Store switcher hash validation** — session fixation, open redirect
6. **ImportExport XML parsing** — potential XXE
7. **Catalog search filter injection** — SQLi via `like` operator

## Magento vs Matomo Comparison

| Aspect | Magento | Matomo |
|--------|---------|--------|
| PHP files | 23,549 | 3,396 |
| Modules/Plugins | ~222 | ~98 |
| Repo size | 732 MB | 339 MB |
| Unauthenticated API | 41 REST + GraphQL | Limited (most need token) |
| Template files | 974 phtml | 304 twig |
| Code readability | Complex (DI, XML config) | Simpler (straightforward MVC) |
| Historical CVEs | Many (RCE, SQLi, XSS) | Fewer |
| Bounty (Critical) | $5K-$15K | Up to $13K |
| Competition | High (popular target) | Lower (niche analytics) |
| Time to first finding | Longer (complex codebase) | Faster (smaller, readable) |

## Audit Status

- **Status**: Attack surface analysis completed 2026-05-13
- **Repo cloned**: Not yet (analysis done via GitHub API)
- **Reports submitted**: None yet
- **Next step**: Clone repo, start with GraphQL mutations and guest checkout flow
