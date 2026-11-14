# Race Conditions Reference

## Attack Surface Signals
- Limit-overrun operations: Redeeming single-use gift cards/coupons, transfer of funds, claiming rewards.
- Time-of-check to time-of-use (TOCTOU) flows: Checking balance before debiting, checking invite quota before adding.
- File operations: Upload → temporary save → AV scan → validation → move.
- High-concurrency endpoints: Rating/voting, checkout reservation, multi-threaded worker queues.

## Attack Primitives & Techniques
1. **HTTP/2 Single-Packet Attack (Synchronized Delivery)**:
   - Multiplex multiple HTTP/2 streams over a single TCP connection.
   - Hold the final frame (or send all request headers with minimal trailers) and release the last byte simultaneously.
   - Ensures sub-millisecond arrival at the backend server, eliminating network jitter.
2. **HTTP/1.1 Pipelining / Keep-Alive Bursting**:
   - Open multiple parallel TCP connections to the server.
   - Pre-warm connections with handshake and send requests synchronized via barrier threads.
3. **Targeted Race Windows**:
   - **Limit Overrun**: Spend 100 credits across 20 concurrent threads to withdraw 500 credits.
   - **Multi-Coupon Stacking**: Apply a single 50% discount coupon 10 times in parallel.
   - **File Race**: Access an uploaded webshell/payload while it resides in `/tmp` before anti-virus or validator deletes it.
   - **Two-Factor Code Brute Force**: Send 1,000 parallel OTP attempts before the rate-limit counter locks the account.

## Common Root Causes
- Non-atomic database transactions: `SELECT balance` followed by separate `UPDATE balance` without row-level locking (`SELECT ... FOR UPDATE`).
- In-memory state checks outside database transaction isolation locks.
- Async worker race: Background worker processing tasks out-of-order.

## Exploit Chains
- **Race Condition → Balance Duplication / Infinite Money**: Double-spending account balance via concurrent withdrawal requests.
- **Race Condition → Privilege Escalation**: Race invitation acceptances to exceed organization member quotas.
- **Race Condition → RCE**: Race temporary file execution before post-processing cleanup.
