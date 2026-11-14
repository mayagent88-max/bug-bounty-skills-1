# Shopware 6 Audit Findings (2026-05-12)

## Confirmed Finding: SSRF via Webhook System (P2-P3)

### Root Cause
`WebhookClient::send()` makes HTTP requests to webhook URLs without SSRF validation.
Shopware HAS `FileUrlValidator` with `FILTER_FLAG_NO_PRIV_RANGE` for media uploads,
but the webhook system does NOT use it.

### Affected Files
- `src/Core/Framework/Webhook/Service/WebhookClient.php` — sends requests without validation
- `src/Core/Framework/Webhook/Handler/WebhookEventMessageHandler.php` — dispatches webhooks
- `src/Core/Framework/App/Lifecycle/Persister/WebhookPersister.php` — persists URLs without validation

### Vulnerable Code
```php
// WebhookClient.php
public function send(WebhookRequest $request): WebhookResult
{
    $response = $this->guzzle->send($request->request, $request->options);
    // No URL validation — SSRF possible
}
```

### Protected Code (comparison)
```php
// FileUrlValidator.php — exists in codebase but NOT used by webhooks
private function validateIpv4(string $ip): bool
{
    return filter_var($ip, FILTER_VALIDATE_IP,
        FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE | FILTER_FLAG_IPV4) !== false;
}
```

### Attack Vector
1. Install malicious app with webhook to `http://169.254.169.254/latest/meta-data/`
2. Trigger event (order placed, customer registered)
3. Server sends request to AWS metadata → credential theft

### PoC Location
`/tmp/bugbounty/shopware-ssrf-poc/` — complete PoC with listener, test script, report

### Submission
Submit at: https://www.shopware.com/en/contact/security-reporting/

## Systemic SSRF Discovery — 7+ Components (P2)

After finding the webhook SSRF, a deeper audit revealed **multiple components** in the app system
that all make HTTP requests to app-controlled URLs without SSRF validation:

| # | Component | File | Method |
|---|-----------|------|--------|
| 1 | Webhook | `WebhookClient.php` | POST to webhook URL |
| 2 | Tax Provider | `TaxProviderPayloadService.php` | POST to `processUrl` |
| 3 | Checkout Gateway | `AppCheckoutGatewayPayloadService.php` | POST to app URL |
| 4 | Action Button | `Executor.php` | POST to `targetUrl` |
| 5 | App Downloader | `AppDownloader.php` | GET to `zipUrl` |
| 6 | In-App Purchases | `InAppPurchasesPayloadService.php` | POST to app URL |
| 7 | Payment Handler | `PaymentPayloadService.php` | POST to app URL |
| 8 | App Context | `AppContextGatewayPayloadService.php` | POST to app URL |

**Key insight**: The `processUrl` field in `TaxProviderDefinition.php` has the `ApiAware` flag,
meaning it can be set via the admin API. This makes the Tax Provider SSRF particularly dangerous.

**Audit methodology**: After finding one SSRF, grep for ALL components that make HTTP requests:
```bash
grep -rn 'guzzle.*post\|guzzle.*get\|client.*request\|client.*post' --include='*.php' src/Core/Framework/App/
```
Then check each one for URL validation. This "follow the pattern" approach often reveals
systemic issues, not just isolated bugs.

**Report strategy**: Report as "Systemic SSRF in App System" — stronger than individual reports
because it shows a design flaw, not just one missing check.

## Other Areas Audited (no high-severity findings)

- **Deserialization**: `FlowLoader` unserializes DB data, but `flow.payload` is `WriteProtected`
- **ImportExport download**: `auth_required: false` but requires valid `accessToken` (cryptographically random)
- **Password reset**: Rate-limited, hash is 32-char alphanumeric (not brute-forceable)
- **Order IDOR**: Properly filtered by `order.orderCustomer.customerId`
- **File upload**: Uses `FileUrlValidator` with SSRF protection
- **SSO endpoints**: Use OAuth2 with proper state validation
- **FileFetcher**: Explicitly sets `follow_location => 0` and `max_redirects => 0` (good security)
- **Open Redirect**: `redirectTo` parameter uses `redirectToRoute()` which only generates internal routes, not external URLs
