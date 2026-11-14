# Subdomain Enumeration & DNS Infrastructure Reference

## Attack Surface Signals
- Root domain targets (`*.target.com`), enterprise IP spaces, multi-tenant cloud deployments.

## The 4-Stage Discovery Pipeline
1. **Passive Enumeration (Zero-Traffic)**:
   - Certificate Transparency logs: `crt.sh`, Censys, SecurityTrails, Chaos, Shodan.
   - Subfinder command:
     `subfinder -d target.com -all -silent -o subfinder.txt`
   - Amass passive:
     `amass enum -passive -d target.com -o amass_passive.txt`
2. **Active Wordlist Brute-Forcing**:
   - Use high-quality wordlists (e.g. Assetnote `best-dns-wordlist.txt` or SecLists `subdomains-top1million-110000.txt`).
   - Clean wildcard DNS with `puredns`:
     `puredns bruteforce best-dns-wordlist.txt target.com -r resolvers.txt -w bruteforce_subs.txt`
3. **Intelligent Permutation Generation**:
   - Generate context-aware mutations from discovered hosts:
     `alterx -l subfinder.txt -enrich -o alterx_subs.txt`
   - Resolve permutations:
     `puredns resolve alterx_subs.txt -r resolvers.txt -w resolved_alterx.txt`
4. **DNS Record & Takeover Auditing**:
   - Extract CNAME records for all live subdomains:
     `dnsx -l all_subs.txt -cname -resp -o cnames.txt`
   - Inspect CNAME destinations for dangling cloud pointers (e.g. `.s3.amazonaws.com`, `.azurewebsites.net`, `.github.io`, `.fastly.net`, `.herokudns.com`).

## Live HTTP Probing & Fingerprinting
- Probe all resolved hosts across standard and alternate web ports:
  `httpx -l all_subs.txt -p 80,443,8000,8080,8443,9000,9090 -title -status-code -tech-detect -content-length -o live_web.txt`

## Exploit Chains
- **Dangling CNAME Record → Subdomain Takeover → Cross-Domain Session Hijacking**.
- **Dev/Staging Subdomain Discovery (`dev-api.target.com`) → Unauthenticated Debug Interface → RCE**.
