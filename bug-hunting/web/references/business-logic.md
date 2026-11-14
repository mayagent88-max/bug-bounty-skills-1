# Business Logic Vulnerabilities Reference

## Attack Surface Signals
- Multi-step workflows: Checkouts, onboarding, identity verification, funds transfer, refunds.
- Numerical parameters: `price`, `quantity`, `discount`, `amount`, `currency`, `balance`, `credits`.
- Coupon / promo code redemption, referral systems, loyalty point conversions.
- Status and state machine transitions: `draft` → `submitted` → `approved` → `paid` → `fulfilled`.

## Testing Methodology & Attack Patterns
1. **Negative & Zero Values**:
   - Negative quantities (`quantity: -1`) to offset prices or inflate credits.
   - Zero amounts (`amount: 0.00`) to bypass payment gateways or obtain free orders.
   - Large integer overflows (`2147483648`, `9223372036854775808`).
2. **Step Skipping & Workflow Ordering**:
   - Call step 3 directly without calling step 1 or 2 (e.g. `/checkout/fulfill` before `/checkout/pay`).
   - Repeat steps out of order (e.g. apply discount code repeatedly, re-initiate payment after approval).
3. **Currency & Unit Conversion Rounding**:
   - Exploit floating-point rounding errors in fractional crypto/currency transactions.
   - Currency manipulation: Pay in weak currency, request refund in strong currency.
4. **Parameter Tampering in Multi-Tier Carts**:
   - Replace item ID mid-transaction while retaining discounted price from previous tier.
   - Submit conflicting body params: `{"cart_total": 100, "items": [{"price": 10, "qty": 1}]}`.
5. **Idempotency & Replay Abuse**:
   - Replay payment success callbacks or webhook signatures.
   - Remove cancellation restrictions: Cancel an already fulfilled order.

## Common Root Causes
- Assumptions that clients will always follow the UI flow sequentially.
- Client-side trust for calculated totals, prices, or operational permissions.
- Incomplete state transition enforcement in backend database/state machines.

## Exploit Chains
- **Logic Flaw → Financial Theft**: Negative item quantity cancels positive total to generate net-positive store credit.
- **State Machine Bypass → Unverified Resource Access**: Skipping KYC verification step by invoking downstream resource generation endpoint directly.
