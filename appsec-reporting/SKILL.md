---
name: appsec-reporting
description: "Findings and report methodology for an appsec pentest run by a pentest-team engagement. Turns the shared FINDINGS.md register into a client deliverable: technical finding format (title, severity, scope, reproduction, evidence, impact, remediation), CVSS v3.1/v4.0 scoring with vector justification, executive summary for non-technical readers, attack-chain narratives, evidence hygiene, coverage/scope/limitations sections, and retest tracking. Load this as the reporter/scribe seam, or whenever an operator files a finding — the finding format here is the register's format."
---

# AppSec Reporting — under the engagement protocol

A great finding lost in a bad report is a wasted finding. The report is the artifact the client pays for and fixes from — treat it with the same rigor as the exploit. On a `pentest-team` engagement the report is not written at the end from memory: it is assembled from `FINDINGS.md`, which every operator wrote into as they worked.

## Under the engagement protocol

- **Only verified findings reach the report.** A finding enters the draft once the verifier has `upheld` it, or `downgraded` it and its owner re-scored the entry (`pt findings show` lists each verdict). `pt findings check` exits 0 before the report ships.
- **The finding format below IS the register format.** Every operator files findings into `.engagement/FINDINGS.md` in this shape — one numbered entry per finding, drafted when confirmed. As reporter you don't rewrite operators' findings; you enforce the format, unify the narrative, and send under-evidenced ones back to their owner.
- **Notify with a pointer, not a body (PROTOCOL §Findings).** The finding lives in `FINDINGS.md`; the wake is one line — "F-0NN filed/verified, <severity>, pull it". Never paste exploit steps, payloads, or a write-up into a message, to anyone — a "quick status" is still a pointer: name the ID, point at the file.
- **Evidence comes from `evidence-ledger.csv` and `.engagement/evidence/`.** Every finding's reproduction and evidence pointers trace to ledger lines the operator logged as they worked. If a finding's evidence isn't in the ledger, it isn't defensible — send it back.
- **Evidence hygiene — keep secrets out of shipped artifacts and out of git.** There is no per-capture redaction discipline: operators capture what proves the finding and move on. The one floor is mechanical and costs no effort — live credentials and out-of-scope data must not reach a *shipped* artifact or git history, enforced by the secret-regex pre-commit hook and the `*-raw.*` sweep (below), not by hand-scrubbing every screenshot.
- **Coverage is part of the deliverable.** The report's scope/coverage section is built from the board: every in-scope target gets a verdict (tested / partially tested / not reachable, with why). A gap stated is worth more than a gap hidden.
- **Scope discipline in the report itself.** No finding, screenshot, or log line references a target outside `ROE.md`'s allowlist.

## Quick workflow

1. Operators capture evidence and draft each finding into `FINDINGS.md` as they confirm it — never reconstruct after the fact.
2. Reporter reviews each finding for the evidence bar as it lands; weak ones go back to the owner.
3. Score every finding (CVSS + business-impact sanity check) before assembling.
4. Build the executive summary last, after all findings are scored and coverage is settled.
5. Two-pass review: technical accuracy first, then read-as-CISO for narrative.
6. Hand off with a retest plan and a JSON/CSV index for the client's tracking system.

## Report structure

```
1. Executive Summary             ← Last to write, first read
2. Engagement Overview
   2.1 Scope (from ROE.md)
   2.2 Methodology
   2.3 Coverage (from the board — every in-scope target's verdict)
   2.4 Limitations / Assumptions
   2.5 Timeline / Team
3. Risk Summary                  ← Heatmap, finding count by severity
4. Technical Findings            ← One per finding, sorted by severity
5. Attack Chains                 ← Critical chains called out separately
6. Strategic Recommendations     ← Programmatic, not finding-by-finding
7. Appendices                    ← Tools, evidence pointers, glossary
```

## Executive summary — the 90-second read

For the CISO and the board; they read this and nothing else. One page max:

1. **Engagement context** — what was tested, when, scope (1 sentence).
2. **Headline finding** — the worst thing found, in business terms (2–3 sentences).
3. **Risk verdict** — overall posture in plain language (1 paragraph).
4. **Counts** — findings by severity, small table.
5. **Top 3 strategic recommendations** — programmatic fixes, not "patch CVE-X".

**Translate every technical term.** "An attacker could run arbitrary commands on the server" — not "RCE via deserialization gadget chain". Words to avoid: `payload`, `RCE`, `XSS`, `IDOR`, `injection`. Words to include: `customer data`, `regulatory exposure`, `account takeover`, `financial loss`. Anchor every finding to a business consequence.

## Technical finding template (register entry)

```markdown
## F-007 — Authenticated SQL Injection in Order Search

**Severity:** Critical (CVSS 9.1 — vector below)
**Affected Scope:** https://app.<in-scope>/api/orders/search (in-scope allowlist item #3)
**Status:** Open / Fixed in retest / Accepted Risk
**Demonstrated impact:** read a planted marker order belonging to tenant B as tenant A — `evidence/F-007/02-extracted-marker.png`
**Owner:** operator-web
**CWE:** CWE-89   **OWASP:** A03:2021 — Injection

### Summary
One paragraph: what it is, why it matters, worst case — in impact terms.

### Reproduction Steps
1. Numbered, copy-paste ready, against the in-scope target only.
2. Exact request/response (swap a live credential for a placeholder only if it would otherwise land in git — no other scrubbing).
3. A reader with no engagement context reproduces in <15 minutes.

### Evidence
- `evidence/F-007/01-injection.http`
- `evidence/F-007/02-extracted-marker.png`
- `evidence-ledger.csv` line 142 (2026-09-04T14:33:07Z)

### Impact
Concrete, proven against the marker — not the whole dataset:
- "Read access to the orders table; verified by reading a planted marker record, not by dumping."

### Remediation
1. **Fix** — parameterized queries / the exact code change.
2. **Defense in depth** — input validation, least-privilege DB account.
3. **Detection** — the log line / SIEM rule that would have caught it.

### References
CWE / OWASP / vendor advisory if a known CVE.

### Notes for Retest
Specific request, specific expected response after the fix.
For a confirmed finding on a re-testable app, also write the capsule-ref
`vault/per-app/<app-key>/confirmed/F-0NN.json` (PROTOCOL §Vault) — pointers to the
positive arm, the negative control, and the evidence, plus its `fix_status`. On a
retest, replay both arms and write the outcome back to that `fix_status`.
```

**The confirmed capsule-ref is the finding's durable half — and the regression worklist is generated from it.** When a finding is `confirmed`, its proof capsule (§Findings: positive arm, negative control, evidence) is durable per-app knowledge: record it as `vault/per-app/<app-key>/confirmed/F-0NN.json`, a capsule-**ref** (`finding_id`, `app_key`, `surface`, `positive_ref`, `negative_ref`, `evidence_ref`, `fix_status`, `verified`, `tags`) that **points at** the evidence, never copies it — no live creds, no raw dumps in the vault. Because it is machine-readable, every `confirmed/*.json` whose `fix_status` is `open`, `held`, or `regressed` is a capsule the next re-test must replay: the regression worklist is a query over the vault, not a memory. The register's `Status:` and the capsule's `fix_status` are the same fact for two readers — the human reads `Status:` (Open / Fixed in retest / Accepted Risk), the re-test reads `fix_status` (`open` | `held` | `regressed` | `fixed` | `accepted-risk`) — so a retest updates both: replay holds → `held`; the positive arm fires again → `regressed`, a fresh finding that re-opens the surface (PROTOCOL §Findings, §Vault); the client's disposition gives `fixed` or `accepted-risk`.

## Severity scoring

CVSS is a tool, not a verdict — score it, then sanity-check against business impact.

```
CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H = 8.5 High
```

Justify each metric in one sentence (`AV:N` — exposed on 443; `PR:L` — needs a low-priv account; `C:H` — full read on the DB). If two operators would score it differently, put the justification in the finding and let the lead arbitrate — that is the Decision-scheme call, not a vibe.

**When CVSS lies.** A "Medium" stored-XSS in the support panel agents use on real PII can outrank an unauthenticated "High" SSRF to a metadata-less service. Score CVSS honestly, then add a **Business Impact Adjustment** paragraph arguing the reporting severity. Never lie with the vector. Use CVSS v4.0 only where the client mandates it (PCI DSS 4.0 trends that way); v3.1 stays the lingua franca. The same gap runs the other way through a control weakness: a CWE-693 (protection-mechanism failure) — a disabled security header, a missing CSRF token, a defense the app documents but never enforces — often scores low in isolation while it is the enabler the rest of a chain rides on; adjust for what it exposes, not what it scores alone.

## Evidence discipline

Every finding traces to `evidence-ledger.csv` lines: `timestamp` (UTC ISO-8601), `operator`, `src`, `target`, `action` (the request/payload), `result`, `evidence_ref`, `notes`. The ledger is append-only; it is the audit trail a mature client asks for.

**The one hygiene gate is mechanical and whole-tree — no per-capture scrubbing.** Operators don't hand-redact each screenshot or HAR; they capture what proves the finding. The floor is that a live secret never reaches *git* or a *shipped* artifact, and that is enforced by two gates, not by discipline: a **secret-regex pre-commit hook** blocks a commit that stages a raw token, cookie, key, or unhashed-PII pattern, and a **tree-wide `*-raw.*` sweep** (`find .engagement -name '*-raw.*'`) must return empty before findings ship (PROTOCOL §Evidence). Both cost zero operator effort and run in the pipeline.

Storage follows the ROE's data-handling rules: encrypted volume, per-engagement key, wipe to client spec at the retention date.

## Attack chains

Critical findings rarely matter alone; the chain is the story and it is its own register entry:

```
1. Reflected XSS in search (F-004, Medium)
2. → steals the session cookie (no HttpOnly, F-009, Low)
3. → session belongs to a support agent with cross-tenant read (F-011, High)
4. = cross-tenant customer-data exposure (Chain C-1, Critical)
```

Write the chain as a narrative finding citing its links — the combination warrants higher severity than any single link, and it is what the executive summary leads with.

## Coverage, scope, limitations

Built from the board and `ROE.md`, these protect both sides:
- **Scope** — the in-scope allowlist and the engagement window, verbatim from ROE.
- **Coverage** — every in-scope target's verdict: tested (checklist run), partially tested (what was and wasn't), not reachable (why — auth wall, out of window, environment down).
- **Limitations / Assumptions** — "internet-only, no internal access"; "staging assumed to mirror prod"; "prod mutations avoided per ROE"; "testing window 22:00–06:00 UTC".

## Strategic recommendations

Below the per-finding fixes, 3–5 programmatic recommendations the CISO presents to the board — "adopt SAST in CI (addresses 12 findings)", "centralize secrets and rotate hardcoded creds (addresses 9)". This is the memorable part; make it count.

## Common mistakes

Reporting a signal as the effect (an error message or a changed status code, with no data, action or code behind it — PROTOCOL §Findings); counting reach beyond the endpoints where the effect was shown; over-CVSSing to inflate the report; undermining the client's triager with vague repro; missing the "so what" (no business impact); a screenshot that leaks a session token; a finding with no ledger line behind it; stopping at the first partial and under-scoring — a layer fell but the operator filed "auth bypassed" at Medium instead of pressing the same break through the next limit to the impact the chain really reaches (PROTOCOL §Findings, "press it to the impact it really leads to"), the under-claim that mirrors reporting a signal as an effect. As reporter, catch these before the human does.
