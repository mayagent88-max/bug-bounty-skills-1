# SAML 2.0 / SSO Vulnerabilities Reference

## Attack Surface Signals
- Enterprise login flows: "Sign in with SSO", `/saml/sso`, `/adfs/ls/`, `/saml2/idp/SSOService.php`.
- HTTP POST requests containing `SAMLResponse` or `SAMLRequest` parameters with base64-encoded XML data.

## Core Attack Techniques
1. **XML Signature Wrapping (XSW 1 - XSW 8)**:
   - **Mechanism**: The backend verifies the signature of one XML element (the signed assertion) but processes a different, injected XML element (the spoofed assertion) for authentication.
   - Inject a duplicate `<saml:Assertion>` containing modified `NameID` (e.g. `admin@victim.com`), placing the legitimate signed assertion in an unexpected wrapper tag.
2. **Signature Stripping / Signature Removal**:
   - Completely delete the `<ds:Signature>` block from the `<saml:Response>` and `<saml:Assertion>`.
   - Broken Service Providers (SPs) check if signature is valid *if present*, but accept unsigned responses if missing.
3. **Certificate & Key Injection (Self-Signed XML Injection)**:
   - Replace `<ds:X509Certificate>` with attacker's generated public certificate.
   - Sign modified assertion with attacker's private key. If SP uses the embedded certificate instead of pre-configured trust store, forgery succeeds.
4. **Recipient & Audience Restriction Tampering**:
   - Modify `<saml:AudienceRestriction>` or `<saml:SubjectConfirmationData Recipient="...">` to cross-authenticate between different SPs sharing the same IdP.
5. **Comment Injection in NameID**:
   - `<saml:NameID>admin<!--comment-->@victim.com</saml:NameID>` -> Some parsers truncate or misread username as `admin`.

## Exploit Chains
- **SAML Signature Stripping / XSW → Impersonate Organization Administrator → Full Tenant Compromise**.
