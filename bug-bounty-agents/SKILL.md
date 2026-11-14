---
name: bug-bounty-agents
description: 43 specialist personas (recon→exploit→report) for bug bounty engagements. Use when a task needs a focused role instead of the general agent.
metadata:
  hermes:
    tags: [security, bug-bounty, personas, red-team]
    category: security
---

# Bug-Bounty-Agents Skill

43 drop-in specialist personas converted from `matty69v/Bug-Bounty-Agents` (MIT). Each is a
full persona file in `references/personas/<name>.md` — read the one that matches the task and
operate as that specialist. Claude-Code-only frontmatter (`tools:`, `model:`) was stripped;
`name` + `description` are preserved.

## When to Use

Use when the task is a distinct engagement role rather than a general question: parsing scan
output, planning an attack path, writing a report, validating a PoC, running a specific
hunter discipline. The general agent handles orchestration; these personas carry the depth.

Do NOT load a persona for a one-line question — answer directly.

## How to Run

1. Pick the persona from the routing table below (match on the task, not the vibe).
2. `read_file` the persona: `~/.hermes/skills/security/bug-bounty-agents/references/personas/<name>.md`
3. Operate under that persona's rules for the duration of the task.
4. `_scope-guard.md` is the shared scope-enforcement block — several personas reference it;
   read it alongside any persona that names it.

## Quick Reference — Routing Table

| Persona | Phase | ATT&CK | Risk | Use for |
|---|---|---|---|---|
| `recon-advisor` | recon | reconnaissance | safe | Surface enumeration and asset discovery |
| `osint-collector` | intel | reconnaissance | safe | Open-source intelligence gathering |
| `subdomain-takeover` | recon | reconnaissance | active | Dangling DNS and takeover validation |
| `threat-modeler` | meta | — | safe | STRIDE / attack-surface modeling |
| `engagement-planner` | meta | — | safe | Scope, RoE, test plan authoring |
| `attack-planner` | meta | — | safe | Multi-stage attack path planning |
| `web-hunter` | web | initial-access | active | Web application vulnerability hunting |
| `api-security` | api | initial-access | active | REST and GraphQL API testing |
| `graphql-hunter` | api | initial-access | active | GraphQL schema, authz, complexity |
| `bizlogic-hunter` | web | initial-access | active | Business logic flaws and abuse cases |
| `ssrf-hunter` | web | initial-access | active | SSRF discovery and filter bypass |
| `jwt-cracker` | web | credential-access | active | JWT/OIDC token attacks |
| `vuln-scanner` | recon | discovery | intrusive | Automated scanning orchestration |
| `cloud-security` | cloud | discovery | active | AWS/GCP/Azure misconfiguration hunting |
| `container-escape` | infra | privilege-escalation | intrusive | Docker/K8s breakout |
| `cicd-redteam` | infra | initial-access | intrusive | CI/CD and supply-chain attacks |
| `ad-attacker` | infra | lateral-movement | intrusive | Active Directory enum and abuse |
| `wireless-pentester` | wireless | initial-access | intrusive | Wi-Fi, Bluetooth, RF assessments |
| `mobile-pentester` | mobile | initial-access | active | iOS/Android application testing |
| `binary-exploit` | exploit | execution | intrusive | Memory corruption, ROP, pwn |
| `crypto-analyst` | exploit | credential-access | safe | Crypto primitive and protocol analysis |
| `hardware-hacker` | exploit | initial-access | intrusive | Embedded, JTAG, firmware extraction |
| `red-team-operator` | postex | command-and-control | intrusive | C2, OPSEC, long-haul operations |
| `purple-team` | defense | — | safe | Detection-as-you-attack collaboration |
| `exploit-chainer` | exploit | execution | active | Combine findings into chains |
| `exploit-guide` | exploit | execution | active | Step-by-step exploitation reference |
| `payload-crafter` | exploit | execution | active | Custom payload generation |
| `credential-tester` | exploit | credential-access | intrusive | Spraying, stuffing, brute force |
| `privesc-advisor` | postex | privilege-escalation | active | Linux/Windows privesc paths |
| `poc-validator` | exploit | — | active | Verify, stabilize, minimize PoCs |
| `llm-redteam` | exploit | initial-access | active | Prompt injection, RAG poisoning |
| `phishing-operator` | exploit | initial-access | intrusive | Phishing infra and campaigns |
| `social-engineer` | exploit | initial-access | intrusive | Pretexting, vishing |
| `malware-analyst` | defense | — | safe | Static and dynamic malware analysis |
| `reverse-engineer` | defense | — | safe | Binary RE, decompilation |
| `forensics-analyst` | defense | — | safe | DFIR, artifact analysis, timelines |
| `ctf-solver` | meta | — | safe | CTF challenge solver |
| `detection-engineer` | defense | — | safe | Detection and response engineering |
| `stig-analyst` | defense | — | safe | STIG/CIS compliance hardening |
| `report-generator` | report | — | safe | Triage-ready bug reports |
| `bug-bounty` | meta | — | active | General-purpose bounty assistant |
| `swarm-orchestrator` | meta | — | safe | Coordinate multiple agents |
| `_scope-guard` | meta | — | safe | Shared scope enforcement block |

## Procedure

1. **Classify the task** into a phase (recon / web / api / exploit / postex / report / meta).
2. **Pick ONE persona** — the most specific match. `web-hunter` for general web work,
   `ssrf-hunter` only when SSRF is the actual subject.
3. **Read the persona file** and adopt its rules, output format, and constraints.
4. **Report back in the operator's register** — the persona shapes the analysis, not the
   reporting style. the operator wants short, results-first, casual Indonesian.

## Pitfalls

- **Personas are prompts, not scanners.** They carry no tooling of their own; the terminal,
  file and browser tools still do the work.
- **`intrusive` risk tier means it touches the target.** Confirm scope before running an
  intrusive persona — the program's out-of-scope list still governs.
- **Do not stack personas.** One persona per task; switching mid-task loses the thread.
- **`swarm-orchestrator` / `attack-planner` are meta** — they coordinate, they do not replace
  the deep skill for the actual technique.
- **Overlap with the 103 hack-skills is intentional.** The hack-skills carry technique depth
  (payloads, bypass matrices); these personas carry role discipline (what to check, in what
  order, what to write down). Load both when the task warrants it.

## Verification

After loading a persona, confirm the file parsed: the frontmatter `name:` must equal the
filename stem, and the body must open with a "You are..." role statement. A persona that
starts with a stripped `tools:` block was converted wrong — re-run the conversion.
