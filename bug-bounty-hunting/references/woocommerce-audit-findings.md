# WooCommerce Audit Findings (2026-05-12)

## Reports Submitted

### 1. Agentic Checkout — Payment Processing Without Per-User Auth (CVSS 8.2) ✅ SUBMITTED
- **Files:** `src/StoreApi/Routes/V1/Agentic/CheckoutSessions.php`, `CheckoutSessionsComplete.php`, `CheckoutSessionsUpdate.php`
- **Issue:** Jetpack blog token (site-level shared secret) is SOLE auth for payment processing
- **Key code:** `AgenticCheckoutUtils::validate_jetpack_request()` only checks `is_signed_with_blog_token()`
- **Impact:** Any entity with blog token can create orders, process Stripe payments without customer involvement
- **5 sub-findings:**
  1. No per-user authorization — blog token = full checkout access
  2. No CSRF protection — `requires_nonce()` returns `false`
  3. Cart-Token JWT user_id not validated — session fixation
  4. Direct `$_SERVER['HTTP_CART_TOKEN']` manipulation — superglobal poisoning
  5. Payment race condition — TOCTOU double-charging
- **HackerOne:** https://hackerone.com/reports/3730157 (same report as Jetpack RCE — combined)

## Other Findings (Not Submitted)

### Store API Unauthenticated Endpoints
- ~46 routes with `permission_callback => '__return_true'`
- Checkout POST, cart manipulation, batch operations
- By design for headless storefronts, but attack surface for logic flaws

### WC-Auth CSRF → API Key Theft
- **File:** `includes/class-wc-auth.php`
- `/wc-auth/v1/authorize` has no nonce verification
- CSRF to generate API keys, exfiltrated to attacker callback URL
- `wp_safe_remote_post` to callback_url — SSRF via DNS rebinding possible

### SQL Injection Candidates
- `InterpolatedNotPrepared` queries in order/product data stores
- `woocommerce_update_product_stock_query` filter — if plugin uses unsanitized input, SQLi possible

### Object Injection
- `unserialize()` in `OrderCouponDataMigrator.php:126`, `LookupDataStore.php:926`
- ~30 `maybe_unserialize()` calls on DB data

### GraphQL Endpoint
- `src/Internal/Api/GraphQLController.php:212-221`
- `permission_callback => '__return_true'` — open route
- Auth handled per-query — potential for bypass

## Key Technique: Blog Token Exploitation Chain
The Jetpack blog token is a site-level shared secret stored in `wp_options`. Any vulnerability that leaks this token (SSRF, SQLi, DB backup exposure, log leak) escalates to:
- **Jetpack RCE** (Backup Helper Script)
- **WooCommerce payment fraud** (Agentic Checkout)
- **Full site compromise**

This creates a vulnerability chain where medium-severity database read becomes critical RCE + financial fraud.

## Key Technique: Legacy vs Modern Code Inconsistency
WooCommerce (like Jetpack) has legacy code paths that bypass newer security controls:
- `Post_To_Url` (legacy) has no URL validation; `Form_Webhooks` (modern) has protection
- Store API `requires_nonce()` returns false on Agentic Checkout
- Always check BOTH legacy and modern code paths
