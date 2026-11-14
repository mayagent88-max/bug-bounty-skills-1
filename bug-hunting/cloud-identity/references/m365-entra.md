# Microsoft 365 & Microsoft Entra ID (Azure AD) Reference

## Attack Surface Signals
- Endpoints: `login.microsoftonline.com`, `autodiscover.target.com`, `login.windows.net`.
- AADSTS error codes in authentication responses.

## Tenant Reconnaissance & User Realm
1. **Domain Federation Discovery**:
   - `curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=user@target.com&xml=1"`
   - `<NameSpaceType>Managed</NameSpaceType>`: Auth handled directly by Entra ID (subject to Smart Lockout).
   - `<NameSpaceType>Federated</NameSpaceType>`: Auth delegated to on-prem ADFS / PingFederate (ADFS lockout rules apply).
2. **OpenID Configuration Extraction**:
   - `curl -s https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration`

## Critical AADSTS Error Code Reference
- **`AADSTS50053`**: Account locked out (Smart Lockout triggered).
- **`AADSTS50055`**: Password expired (Valid credentials confirmed).
- **`AADSTS50056`**: User does not have password in directory (Valid user).
- **`AADSTS50057`**: User account is disabled (Valid user).
- **`AADSTS50059`**: No tenant found in directory.
- **`AADSTS50126`**: Invalid username or password (Invalid password for valid user).

## Smart Lockout & Spray Discipline
- Entra ID Smart Lockout defaults: 10 failed attempts trigger a 60-second lockout.
- Cap spray rate: 1 attempt per account per 60 minutes to completely evade lockout triggers.
- Probe legacy protocol endpoints (ActiveSync, IMAP/POP3) which often bypass conditional access and MFA policies.

## Exploit Chains
- **Tenant Realm Discovery → Legacy Endpoint Password Spray → Corporate Email & SharePoint Access**.
