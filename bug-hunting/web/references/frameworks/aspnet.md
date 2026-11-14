# ASP.NET & IIS Hunting Reference

## Attack Surface Signals
- Extensions: `.aspx`, `.ashx`, `.asmx`, `.axd`, `.svc`.
- Headers: `X-Powered-By: ASP.NET`, `Server: Microsoft-IIS`, cookie `ASP.NET_SessionId`, `__VIEWSTATE`.

## Core Flaw Patterns & Exploitation
1. **ViewState Insecurity & Deserialization**:
   - Check if `__VIEWSTATE` is unencrypted (MAC enabled vs disabled).
   - If `machineKey` (validation key / decryption key) leaks (via config disclosure, XXE, LFI, or source leaks):
     - Generate RCE payload using `ysoserial.net -p ViewState -g ActivitySurrogateSelector -c "cmd" --path="/app" --apppath="/" --decryptionalg="AES" --decryptionkey="..." --validationalg="SHA1" --validationkey="..."`.
2. **Telerik Web UI Handlers (`Telerik.Web.UI.WebResource.axd`)**:
   - CVE-2017-11317 / CVE-2019-18935: Deserialization RCE via `rauPostData` and `type` manipulation.
3. **Trace & Diagnostics Exposure**:
   - Check `/trace.axd`, `/elmah.axd`, `/glimpse.axd` (often exposes live session cookies and raw query strings).
4. **Request Validation Bypasses**:
   - RequestValidator discrepancies with URL encoding and trailing characters.

## Exploit Chains
- **Leaked machineKey / Unencrypted ViewState → Remote Code Execution**.
