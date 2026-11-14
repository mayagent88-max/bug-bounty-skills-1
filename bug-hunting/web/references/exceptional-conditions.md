# Exceptional Conditions & Parser Differential Reference

## Attack Surface Signals
- Systems using multiple distinct parsers (WAF + Reverse Proxy + Web Framework + Database).
- High-stress or abnormal inputs causing partial error handling, state desynchronization, or fallback modes.

## Attack Patterns & Edge Cases
1. **Parser Differential Exploits**:
   - JSON key duplication: `{"admin": false, "admin": true}` (some parsers use first key, others use last key).
   - URI normalization discrepancies: Traversal sequences `%2e%2e%2f` vs `/..;/` vs `/.//`.
2. **Payload Size & Truncation Boundary Testing**:
   - Massive headers (e.g. 8KB `Cookie` or `User-Agent`) triggering buffer overflow or bypass of downstream security filters.
   - Long strings causing database column truncation (e.g. registering `admin                @evil.com` truncated to `admin`).
3. **Character Encoding Confusion**:
   - UTF-7, UTF-8 overlong encodings (`%c0%ae`), Unicode normalization (Kelvin sign `K` normalizing to `K`).
4. **Type Juggling & Type Confusion**:
   - In loose languages (PHP, JavaScript): `{"password": true}` or `0 == "admin"`.
5. **Partial Failures in Distributed Workflows**:
   - Triggering error on step 2 after step 1 commits, without rollback.

## Exploit Chains
- **Parser Differential → WAF / Auth Filter Bypass**.
- **Truncation / Encoding Normalization → Account Impersonation**.
