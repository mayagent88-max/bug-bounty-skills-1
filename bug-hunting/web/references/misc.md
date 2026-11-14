# Miscellaneous Web Vulnerabilities Reference

## Attack Surface & Topics
- Sensitive File / Backup Exposure (`.git`, `.env`, `.bak`, `.swp`, `phpinfo.php`, `web.config`, `Dockerfile`).
- Information Disclosure (stack traces, verbose error messages, software version headers).
- Subdomain Takeovers (dangling CNAME / DNS records pointing to unclaimed S3, GitHub Pages, Heroku, Azure).
- Open Debugging & Profiling Interfaces (Swagger UI, GraphQL Playground, PHP DebugBar, Django Debug Toolbar).

## Verification & Key Commands
1. **Source Code & Git Leaks**:
   - Check `/.git/HEAD`, `/.git/config`, `/.env`, `/.DS_Store`, `/backup.zip`, `/dump.sql`.
   - Tooling: `git-dumper` or `githacker` to reconstruct repository.
2. **Subdomain Takeover**:
   - Identify dangling CNAME: `dig CNAME sub.target.com`.
   - Look for provider error responses: "There isn't a GitHub Pages site here", "NoSuchBucket", "404 Not Found" on AWS S3/Azure/Fastly.
3. **Debug Consoles & Exposed Metrics**:
   - Check `/_debugbar/`, `/__debug__/`, `/swagger-ui.html`, `/metrics`, `/health`.

## Exploit Chains
- **Dangling CNAME → Subdomain Takeover → Session Cookie / OAuth Code Theft**.
- **Exposed `.env` / `.git` → Cloud Secret Extraction → Full Infrastructure Takeover**.
