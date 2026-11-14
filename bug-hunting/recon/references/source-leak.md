# Source Code & Repository Leak Hunting Reference

## Attack Surface Signals
- Web root directories, exposed source maps, public GitHub/GitLab organizations, employee personal repositories.

## Leak Detection Vectors
1. **Exposed Web Root Metadata Files**:
   - `/.git/HEAD`, `/.git/config`, `/.git/index` -> Extract with `git-dumper https://target.com/.git/ ./git_dump`
   - `/.env`, `/.env.local`, `/.env.production`, `/web.config`, `/Dockerfile`, `/docker-compose.yml`
   - `/.DS_Store`, `/.vscode/settings.json`, `/server-status`, `/phpinfo.php`
   - Database & Backup dumps: `/dump.sql`, `/backup.zip`, `/backup.tar.gz`, `/db.sqlite3`.
2. **Production Source Map (.js.map) Extraction**:
   - Search JS bundles for `sourceMappingURL`:
     `curl -s https://target.com/static/js/app.js | grep -o 'sourceMappingURL=.*'`
   - Unpack full client-side and backend shared source trees:
     `npx restore-source-tree -o ./unpacked_src https://target.com/static/js/app.js.map`
3. **Public GitHub Organization & Employee Repo Scraping**:
   - Scan target organization and developer personal accounts using `trufflehog` or `gitleaks`:
     `gitleaks detect --source ./repo -v`
     `trufflehog github --org=target_org`

## Exploit Chains
- **Exposed `.git/` Directory → Reconstruct Source Code → Hardcoded Master DB Password Extraction**.
- **Unpacked Source Map → Internal API Secret Token Leaked → Admin Authorization Bypass**.
