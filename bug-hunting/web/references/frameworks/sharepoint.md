# Microsoft SharePoint Hunting Reference

## Attack Surface Signals
- Paths: `/_layouts/15/`, `/_vti_bin/`, `/_api/web/`, `ToolPane.aspx`, `FormDigest`.
- Headers: `MicrosoftSharePointTeamServices`, `SPRequestGuid`, `X-SharePointHealthScore`.

## Vulnerability Patterns & Chains
1. **CVE-2025-53770 / CVE-2023-29357 (Auth Bypass & ToolShell RCE)**:
   - Pre-auth / post-auth chain exploiting signed-only ViewState in `ToolPane.aspx` combined with anonymous FormDigest generation.
2. **API & Endpoint Authorization Flaws**:
   - `/_vti_bin/client.svc`, `/_vti_bin/ListData.svc` returning full list schema and documents without proper ACL checks.
3. **SOAP & WCF Service Endpoints**:
   - Exposed web services in `/_vti_bin/*.asmx` (e.g. `UserGroup.asmx`, `Lists.asmx`) allowing user enumeration or unauthorized item creation.
4. **Information Disclosure**:
   - Sensitive site templates, permission lists, and SharePoint internal farm details reachable via `/_api/` endpoints.

## Exploit Chains
- **SharePoint ToolPane ViewState Deserialization → SYSTEM Remote Code Execution**.
- **`_vti_bin` Endpoint Misconfiguration → Sensitive Internal Document Exfiltration**.
