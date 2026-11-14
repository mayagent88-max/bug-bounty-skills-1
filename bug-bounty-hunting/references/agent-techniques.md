# Bug Bounty Agent Techniques Reference

## Agent: web-hunter
### Web Application Testing Methodology
1. **Spider/crawl** the application
2. **Map all endpoints** — forms, APIs, redirects
3. **Test each input** — XSS, SQLi, command injection
4. **Check authentication** — session management, cookies
5. **Test authorization** — IDOR, privilege escalation
6. **Check file uploads** — type validation, path traversal
7. **Test business logic** — workflow bypass, race conditions

### Directory Brute Forcing
```bash
# Common wordlists
gobuster dir -u https://target.com -w /usr/share/wordlists/dirb/common.txt
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/dirb/common.txt
```

## Agent: api-security
### REST API Testing
1. **Enumerate endpoints** — Swagger/OpenAPI, JS files, proxy
2. **Test CRUD operations** — create, read, update, delete
3. **Test authentication** — JWT, OAuth, API keys
4. **Test authorization** — IDOR, role-based access
5. **Test input validation** — injection, type confusion
6. **Test rate limiting** — brute force, enumeration

### API-Specific Payloads
```
# IDOR
GET /api/users/1 → GET /api/users/2

# Mass Assignment
POST /api/users {"role": "admin"}

# Parameter Pollution
GET /api/users?id=1&id=2

# Method Override
POST /api/users/1 → DELETE /api/users/1
```

## Agent: exploit-chainer
### Chain Building Process
1. **Collect all findings** — even low-severity
2. **Map dependencies** — which findings enable others
3. **Build attack graph** — visualize chains
4. **Test chains** — verify each step works
5. **Document impact** — calculate combined severity

### Common Chains
- **XSS + CSRF** → Account takeover
- **SSRF + Internal API** → Admin access
- **IDOR + Weak Auth** → Data breach
- **Info Disclosure + Brute Force** → Credential stuffing

## Agent: bizlogic-hunter
### Business Logic Testing
1. **Map normal workflow** — step by step
2. **Skip steps** — jump to later steps
3. **Repeat steps** — replay same step
4. **Manipulate values** — negative, zero, extreme
5. **Test race conditions** — concurrent requests
6. **Test state transitions** — invalid state changes

### Common Business Logic Flaws
- **Price manipulation** — negative quantities, decimal overflow
- **Coupon abuse** — reuse, stack, combine
- **Order manipulation** — change status, skip payment
- **Privilege escalation** — access admin functions
- **Workflow bypass** — skip verification steps

## Agent: graphql-hunter
### GraphQL Testing
1. **Introspection** — get full schema
2. **Query depth** — test for nested query DoS
3. **Batch queries** — bypass rate limits
4. **Field access** — test authorization per field
5. **Mutation testing** — test write operations

### GraphQL Payloads
```graphql
# Introspection
{__schema{types{name,fields{name}}}}

# Deep query (DoS)
{user{friends{friends{friends{friends{name}}}}}}

# Batch query
[{"query":"{user(id:1){email}}"},{"query":"{user(id:2){email}}"}]
```

## Agent: jwt-cracker
### JWT Attack Vectors
1. **Algorithm confusion** — RS256→HS256, alg:none
2. **Weak secret** — dictionary attack on HMAC
3. **Kid injection** — path traversal, command injection
4. **JWKS injection** — point to attacker JWKS
5. **Claim manipulation** — change sub, role, exp

### JWT Tools
```bash
# Decode JWT
jwt_tool <token>

# Brute force secret
hashcat -m 16500 jwt.txt wordlist.txt

# Test alg:none
jwt_tool <token> -X a
```

## Agent: payload-crafter
### Payload Crafting Tips
1. **Context-aware** — HTML, JS, SQL, command
2. **Encoding** — URL, HTML, Base64, Unicode
3. **Filter bypass** — case variation, comments, concatenation
4. **Polyglot** — work in multiple contexts
5. **Minimal** — smallest payload that proves impact

### XSS Payloads
```javascript
// Basic
<script>alert(1)</script>

// Event handler
<img src=x onerror=alert(1)>

// SVG
<svg onload=alert(1)>

// Angular
{{constructor.constructor('alert(1)')()}}

// Template injection
${alert(1)}
```

## Agent: poc-validator
### PoC Validation Checklist
1. **Reproducible** — works every time
2. **Minimal** — smallest possible PoC
3. **Safe** — no destructive actions
4. **Documented** — clear steps
5. **Evidence** — screenshots, logs, timestamps

## Agent: report-generator
### Report Quality Checklist
- [ ] Clear title
- [ ] Accurate severity rating
- [ ] Affected component identified
- [ ] Root cause explained
- [ ] Steps to reproduce numbered
- [ ] PoC included
- [ ] Impact described
- [ ] Remediation suggested
- [ ] No PII/secrets in report
- [ ] Screenshots/logs attached
