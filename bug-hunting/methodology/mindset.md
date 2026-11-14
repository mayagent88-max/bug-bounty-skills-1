---
name: bug-hunting-mindset
description: The hunter's core decision loop -- how to approach any target regardless of vuln class. Read once, not per-target.
---

# The Bug Hunter's Mindset & Decision Loop

Bug hunting is not running automated scanners or blindly spraying checklists against arbitrary endpoints. It is an adversarial investigation loop based on three immutable principles:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. MAP WIDE        Complete attack surface visibility       │
│         │                                                   │
│         ▼                                                   │
│ 2. HYPOTHESIZE     Keep multiple plausible classes alive    │
│         │                                                   │
│         ▼                                                   │
│ 3. CONFIRM STRICT  Behavioral & differential proof only     │
│         │                                                   │
│         ▼                                                   │
│ 4. REPORT SOLID    Triage-proof evidence & exact impact     │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. The 4-Stage Decision Loop

### Stage 1: Map Wide (Recon Before Reflex)
- Never start testing inputs on the main homepage before mapping all subdomains, APIs, mobile apps, and microservice routes.
- The best bugs hide in forgotten assets: staging portals, deprecated API versions (`/api/v1/`), unlinked internal tools, and secondary microservices.
- Understand the app's business domain: Who are the users? What constitutes money, privacy, or administrative control?

### Stage 2: Hypothesize Wide (Avoid Single-Class Tunnel Vision)
- When inspecting an input, do not assume a single vulnerability class.
- Ask: *"What could this input become?"*
  - An `id` parameter could be **IDOR**, or **SQLi**, or **Access Control Bypass** if set to `admin`.
  - A `url` parameter could be **SSRF**, or **Open Redirect**, or **IDOR** if used as a database lookup key.
- Keep all plausible hypotheses alive until empirical response data rules them out.

### Stage 3: Confirm Strict (No Guesswork)
- A finding does not exist until you have proven differential behavior.
- **Read IDOR**: Must return real, private data from Account A when queried by Account B.
- **Blind SSRF / XXE / RCE**: Must produce verifiable out-of-band network callbacks (DNS/HTTP interactsh).
- **Rate Limit Bypass**: Must demonstrate state execution beyond configured thresholds (e.g. 50+ successful password resets).
- Never report speculative or purely theoretical issues (e.g. "missing header could lead to attack").

### Stage 4: Report Solid (Triage-Proof)
- Present reproduction steps so simple and clear that a triage engineer can reproduce the bug in 60 seconds without ambiguity.

---

## Appendix: Core Tool Arsenal & Fast Commands

| Task | Preferred Tool | Quick Command |
|---|---|---|
| **Subdomain Enum** | `subfinder` | `subfinder -d target.com -all -silent -o subs.txt` |
| **DNS Resolution** | `puredns` | `puredns resolve subs.txt -r resolvers.txt -w live.txt` |
| **HTTP Probing** | `httpx` | `httpx -l live.txt -status-code -title -tech-detect -o web.txt` |
| **Web Fuzzing** | `ffuf` | `ffuf -u https://target.com/FUZZ -w wordlist.txt -mc 200,301,302` |
| **OOB Callbacks** | `interactsh-client` | `interactsh-client -v` |
| **Parameter Mining**| `arjun` / `paramspider` | `arjun -u https://target.com/api/endpoint -m GET` |
| **Secret Scanning** | `trufflehog` | `trufflehog github --org=target_org` |
| **APK Decompile** | `jadx` | `jadx -d out/ target.apk --show-bad-code` |
