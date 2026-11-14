# Okta Identity Cloud Attacks Reference

## Attack Surface Signals
- Domains: `*.okta.com`, `*.oktapreview.com`, `*.okta-emea.com`.
- Endpoints: `/.well-known/webfinger`, `/api/v1/authn`, `/oauth2/default`, `/login/default`.

## Reconnaissance & Discovery
1. **Tenant Identification via WebFinger**:
   - `curl "https://target.com/.well-known/webfinger?resource=okta:idx:user&rel=okta:idx:user"`
   - Directly reveals tenant URL: `https://company.okta.com`.
2. **User Enumeration**:
   - Probe `/api/v1/authn` with `{"username": "user@target.com", "options": {"warnBeforePasswordExpired": true}}`:
     - Valid user: Returns `PASSWORD_WARN` or `LOCKED_OUT` or specific error state.
     - Invalid user: Returns generic error message with timing differential.

## Attack Vectors & Bypasses
1. **Push Fatigue / Prompt Bombing**:
   - Trigger repeated Okta Verify push notifications outside business hours to prompt accidental user acceptance.
2. **FastPass & Device Trust Bypass**:
   - Intercept device registration tokens or inspect whether non-managed devices are routed to legacy MFA.
3. **Application Routing & IdP Discovery Confusion**:
   - Modify email domain suffix in multi-IdP environments to route authentication to an attacker-controlled SAML IdP.
4. **Over-Permissive OAuth Scopes**:
   - Request broad OpenID scopes (`okta.users.read`, `okta.apps.read`) during third-party app authorization.

## Exploit Chains
- **Okta User Enumeration → Targeted Password Spraying → Single Sign-On Access to Corporate SaaS Suite**.
