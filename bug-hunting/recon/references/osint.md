# Enterprise OSINT & Attack Surface Mapping Reference

## Attack Surface Signals
- Target company name, brand acquisitions, employee profiles, public SaaS surfaces, third-party vendor integrations.

## Reconnaissance Domains & Methodology
1. **Identity Fabric & Corporate Email Formats**:
   - Identify corporate email naming conventions:
     - Search Hunter.io, RocketReach, LinkedIn.
     - Formats: `{first}.{last}@target.com`, `{f}{last}@target.com`, `{first}@target.com`.
   - Discover employee identities for password spraying and social engineering.
2. **SaaS Public Surface Enumeration**:
   - Check standard third-party corporate SaaS instances:
     - Atlassian Jira / Confluence: `https://target.atlassian.net`
     - Salesforce / Force.com: `https://target.my.salesforce.com`
     - Zendesk Help Center: `https://target.zendesk.com`
     - Statuspage: `https://target.statuspage.io`
     - Slack Workspace: `https://target.slack.com`
     - Notion / Coda public workspaces.
3. **Corporate Infrastructure & ASN Mapping**:
   - Find registered autonomous system numbers and IP prefixes:
     `whois -h whois.radb.net -- '-i origin AS<NUMBER>'`
     `curl -s "https://api.bgpview.io/asn/<NUMBER>/prefixes" | jq .`
4. **Breach & Historical Credential Analysis**:
   - Check DeHashed / LeakCheck / HaveIBeenPwned for historical password reuse patterns matching current employees.

## Exploit Chains
- **SaaS Workspace Discovery (Public Jira/Confluence) → Internal Architecture Docs & Credentials Leaked**.
- **Employee Identity Mapping → Credential Spraying on SSO Portal → Corporate Network Access**.
