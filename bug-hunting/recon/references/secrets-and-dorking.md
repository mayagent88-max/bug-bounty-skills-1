# Google/GitHub Dorking & Secret Patterns Reference

## Google Search Dorking Corpus
- **Exposed File Types**:
  - `site:target.com filetype:env | filetype:yml | filetype:yaml | filetype:json | filetype:sql | filetype:conf`
  - `site:target.com ext:log | ext:bak | ext:old | ext:sql | ext:zip`
- **Admin Panels & Sensitive Interfaces**:
  - `site:target.com inurl:admin | inurl:dashboard | inurl:login | inurl:portal`
  - `site:target.com inurl:swagger | inurl:api-docs | inurl:graphql | inurl:actuator`
- **Index Of Directory Listings**:
  - `site:target.com intitle:"index of" | intitle:"index.of"`

## GitHub Code Search Dorking
- `org:target "password" OR "secret" OR "apikey" OR "token"`
- `org:target "BEGIN RSA PRIVATE KEY"`
- `org:target filename:.env OR filename:credentials.json OR filename:id_rsa`
- `"target.com" "Authorization: Bearer"`

## Regex Secret Pattern Catalog & Validation
1. **AWS Access Keys**:
   - Regex: `(A3T[A-Z0-9]|AKIA[0-9A-Z]{16}|AGPA[0-9A-Z]{16}|AIDA[0-9A-Z]{16}|AROA[0-9A-Z]{16}|AIPA[0-9A-Z]{16}|ANPA[0-9A-Z]{16}|ANVA[0-9A-Z]{16}|ASIA[0-9A-Z]{16})`
   - Validation: `aws sts get-caller-identity`
2. **GitHub Personal Access Tokens**:
   - Regex: `ghp_[a-zA-Z0-9]{36}`, `github_pat_[a-zA-Z0-9_]{82}`
   - Validation: `curl -H "Authorization: token ghp_..." https://api.github.com/user`
3. **Slack Webhooks & Bot Tokens**:
   - Regex: `https://hooks.slack.com/services/T[a-zA-Z0-9_]+/B[a-zA-Z0-9_]+/[a-zA-Z0-9_]+`, `xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+`
   - Validation: `curl -X POST -H 'Content-type: application/json' --data '{"text":"test"}' https://hooks.slack.com/...`
4. **Stripe API Keys**:
   - Regex: `sk_live_[0-9a-zA-Z]{24}`
   - Validation: `curl https://api.stripe.com/v1/charges -u sk_live_...:`

## Exploit Chains
- **GitHub Dork → Leaked Production Stripe API Key → Financial Charge / Refund Exploitation**.
- **Google Dork → Exposed S3 Database Backup → Plaintext Customer Data Dump**.
