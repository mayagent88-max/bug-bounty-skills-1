# Credential Attacks & Password Spraying Reference

## Attack Surface Signals
- Login endpoints, single-sign on portals, corporate VPNs, O365 / Entra portals, basic auth prompts.

## The 4-Stage Attack Pipeline
1. **Target Harvesting**:
   - Harvest valid corporate email addresses via LinkedIn, hunter.io, and corporate website directories.
   - Standardize format: `first.last@target.com` vs `flast@target.com`.
2. **Lockout Policy & Threshold Validation**:
   - Determine lockout limits before spraying: 3, 5, or 10 attempts before account lockout.
   - Check lockout duration: 15, 30, or 60 minutes.
3. **Controlled Password Spraying (1 Password across N Users)**:
   - Pick high-probability passwords matching corporate seasonal standards:
     - `SeasonYear!` (e.g. `Spring2026!`, `Winter2025!`)
     - `CompanyYear!` (e.g. `Target2026!`)
     - `Welcome1!`, `Password123!`
   - Spray 1 password across the entire userlist.
   - Enforce mandatory sleep delay (e.g. 60-90 minutes) before attempting second password candidate.
4. **Success Detection & Triage**:
   - Check response size, HTTP status (`302 Redirect` to `/app`), and session cookies.
   - Immediately cease testing against confirmed account to avoid lockout or alerting.

## Hard Operational Guards
- **NEVER** run classic brute-force (1 user across N passwords) against production enterprise accounts.
- **NEVER** exceed 1 attempt per account per lockout window.
- Distribute spray traffic across multiple rotating IP addresses (AWS API Gateway / proxy chains).

## Exploit Chains
- **1-Password Spray → Valid Domain User Compromise → Corporate VPN Access → Internal Domain PrivEsc**.
