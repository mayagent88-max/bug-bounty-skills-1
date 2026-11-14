---
name: recon-router
description: Attack-surface discovery and OSINT procedure -- run this FIRST, before any vuln-class hunting, to map what's actually there.
---

# Reconnaissance & Attack Surface Discovery — Procedure

> [!IMPORTANT]
> Run this procedure FIRST before selecting any vulnerability class. Recon is not about finding bugs directly — it is about mapping 100% of the target's external footprint, resolving asset ownership, triaging in-scope domains, and routing discovered technologies into specialized domain guides.

---

## The 5-Phase Reconnaissance Pipeline

```
[Target Organization Name / Root Domain]
                 │
                 ▼
 ┌───────────────────────────────┐
 │ 1. Scope & Ownership Triage   │  ASNs, CIDRs, Acquisitions, Root Domains
 └───────────────┬───────────────┘
                 │
                 ▼
 ┌───────────────────────────────┐
 │ 2. Subdomain & Host Discovery │  Passive (Certificates/APIs) + Active (Permutations/DNS)
 └───────────────┬───────────────┘
                 │
                 ▼
 ┌───────────────────────────────┐
 │ 3. Port & HTTP Probing        │  Live Hosts, Ports, Status Codes, Tech Fingerprinting
 └───────────────┬───────────────┘
                 │
                 ▼
 ┌───────────────────────────────┐
 │ 4. OSINT & Secret Discovery   │  GitHub Leaks, Source Maps, Dorking, Exposed Backups
 └───────────────┬───────────────┘
                 │
                 ▼
 ┌───────────────────────────────┐
 │ 5. Domain Router Handoff      │  Route endpoints into Web / API / Cloud / Mobile / AI
 └───────────────────────────────┘
```

---

## Step 1: Scope & Ownership Triage
1. **Define Strict Program Scope**:
   - In-scope wildcards: `*.target.com`, explicitly listed domains, mobile apps, or IP ranges.
   - Out-of-scope targets: Third-party SaaS providers (e.g. `zendesk.com`, `statuspage.io`), partner portals, de-scoped production billing flows.
2. **Autonomous System (ASN) & IP Range Enumeration**:
   - `amass intel -org "Target Inc"` or `whois -h whois.radb.net -- '-i origin AS12345'`
   - BGP routing tables via bgp.he.net to discover enterprise CIDR ranges.

## Step 2: Subdomain Enumeration (Passive & Active)
1. **Passive Aggregation**:
   - Query Certificate Transparency logs and aggregation APIs:
     `subfinder -d target.com -all -silent -o passive_subs.txt`
2. **Active Permutation & Brute-Force**:
   - Generate intelligent permutations from seed words:
     `alterx -l passive_subs.txt -o permutations.txt`
   - Resolve at scale with high-performance resolvers:
     `puredns resolve permutations.txt -r resolvers.txt -w resolved_subs.txt`
3. **Dangling DNS Takeover Check**:
   - Check all resolved CNAME records for de-provisioned CloudFront, S3, Azure, or GitHub Pages buckets.
   - Load [`references/subdomain-enum.md`](references/subdomain-enum.md) for full commands.

## Step 3: Service Probing & Technology Fingerprinting
1. **HTTP/HTTPS Probing**:
   - Probe live web services, recording title, status code, content-length, and web server:
     `httpx -l resolved_subs.txt -title -tech-detect -status-code -content-length -o live_http.txt`
2. **Port Scanning Non-Standard Services**:
   - `naabu -l resolved_subs.txt -top-ports 1000 -o open_ports.txt`

## Step 4: OSINT, Secret Leaks & Dorking
1. **Public GitHub & Source Leaks**:
   - Search GitHub repositories, commits, and gists for leaked API keys, tokens, and private domain references.
   - Extract source maps (`.js.map`) from production SPAs.
   - Load [`references/source-leak.md`](references/source-leak.md) and [`references/secrets-and-dorking.md`](references/secrets-and-dorking.md).
2. **Identity & Breach OSINT**:
   - Map corporate email conventions, employee identity fabric, and corporate SaaS endpoints.
   - Load [`references/osint.md`](references/osint.md).

## Step 5: Handoff to Domain Routers

| Discovered Target Profile | Next Action / Domain Guide to Load |
|---|---|
| Standard web application, user portals, administrative consoles | Load [`../web/ROUTER.md`](../web/ROUTER.md) |
| REST APIs, GraphQL endpoints, gRPC services, WebSocket endpoints | Load [`../api/ROUTER.md`](../api/ROUTER.md) |
| Exposed Cloud storage (S3), K8s APIs, CI/CD pipelines, Okta/Entra SSO | Load [`../cloud-identity/ROUTER.md`](../cloud-identity/ROUTER.md) |
| Android APKs, iOS IPAs, desktop thick-client binaries | Load [`../mobile/ROUTER.md`](../mobile/ROUTER.md) |
| AI chatbots, agent tool-calling features, RAG knowledge bases | Load [`../ai-llm/ROUTER.md`](../ai-llm/ROUTER.md) |
