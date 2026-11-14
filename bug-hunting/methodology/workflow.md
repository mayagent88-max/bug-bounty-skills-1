---
name: bug-hunting-workflow
description: The operating discipline a world-class hunter follows on every target -- the per-target working folder, the recon-before-exploit gate, the hypothesis log, and the resume/handoff record. Run this BEFORE picking a domain router. This is administrative discipline, not technique -- it's what separates a hunter who systematizes from one who doesn't, regardless of how much technique either knows.
---

# Bug Hunting — Operating Workflow

Knowing every vuln class in this skill's domain routers is not what makes a hunter effective. What separates a systematic hunter from someone with the same knowledge is boring, administrative discipline: never losing track of what's been tried, never skipping recon to chase one interesting param, never reporting before confirming, never starting a resumed session from zero. This file is that discipline, made concrete as real files and a real sequence.

**Run this as Step 0 of any real hunt** — before loading any domain `ROUTER.md` from `../SKILL.md`.

---

## 1. Set up the target's working folder — before sending a single request

Create the folder immediately, named after the target (sanitized: lowercase, hyphens, no special chars):

```
./<target-name>/
  scope.md              <- what's in scope, what's explicitly out, program rules
  recon/
    endpoints.txt        <- every discovered endpoint, one per line, as found
    tech-stack.md         <- frameworks/tech fingerprinted (feeds domain routers)
    auth-notes.md          <- how auth works, what accounts/tokens you hold
  hypothesis-log.md       <- every vuln class considered, per endpoint, dated
  findings/
    001-<short-name>.md    <- one file per CONFIRMED finding, numbered in order found
  session-notes.md         <- current state, next step, resume point
```

**Write `scope.md` first, before anything else.** Copy the program's in-scope/out-of-scope rules into it verbatim. Every later action checks against this file, not memory — memory drifts over a long session, a file doesn't.

If the user hasn't given you a working directory, ask, or default to a subfolder of the current directory named after the target. Never skip creating this structure because the engagement "seems small" — the folder costs nothing to create and the discipline only pays off if it's automatic, not situational.

---

## 2. Recon phase gate — do not open a domain router until recon is marked done

This is the single most common discipline failure: spotting one promising-looking param and immediately switching to exploitation, leaving the rest of the surface unmapped. A hunter who does this finds one bug and misses three sitting next to it.

- Work through `recon/ROUTER.md` first, completely, for the current target.
- Populate `recon/endpoints.txt` and `recon/tech-stack.md` as you go — not from memory, write them as discovered.
- Only once recon feels complete, write one line at the top of `session-notes.md`: `RECON COMPLETE: <date>`.
- **Only after that line exists** should any other domain router (`web/`, `api/`, `mobile/`, `cloud-identity/`, `ai-llm/`) be loaded.

Exception: if the user explicitly hands you a single known endpoint to test right now ("just check this one IDOR"), you can skip the gate for that one ask — but say so explicitly, and still log it in `hypothesis-log.md`.

---

## 3. The hypothesis log — track every class considered, not just the ones that hit

For every endpoint × vuln-class combination you seriously consider (i.e., you looked at a domain router's signal table and it pointed here), add one line to `hypothesis-log.md`:

```
2026-08-26 | /api/orders/{id} | idor_bola | TRIED | swap to victim's order id, same-session -> 403, REFUTED
2026-08-26 | /api/orders/{id} | mass_assignment | TRIED | extra "status":"paid" field -> ignored, REFUTED
2026-08-26 | /api/fetch?url=  | ssrf | CONFIRMED | -> findings/001-ssrf-fetch-metadata.md
2026-08-26 | /api/webhook     | ssrf | NOT-YET | needs OOB listener, queued
```

This log is what makes a long session efficient instead of repetitive: before testing anything, grep this file first. A refuted hypothesis stays refuted unless something changes (a new account, a new permission level) — don't re-test it out of habit. A `NOT-YET` entry is a todo list that survives a session restart.

---

## 4. Confirm-before-report gate

A line in the hypothesis log only becomes a file in `findings/` once it passes the confirmation bar from the matching domain router AND `../methodology/reporting.md`'s validation checklist — reproduced, in scope, evidence captured. Never write a `findings/*.md` file for something still marked `TRIED` with an inconclusive result. This mirrors the core rule from `mindset.md`: report only what you proved.

---

## 5. Session handoff — resuming without starting over

At the end of any working session (context running low, user pausing, natural stopping point), update `session-notes.md` with:

- What's confirmed so far (pointer to `findings/`, don't restate).
- What's actively in progress (pointer to the `NOT-YET` lines in the hypothesis log worth following up).
- The single next concrete action to take when resuming.

When picking up a target again, **read `session-notes.md` and `hypothesis-log.md` first**, before doing anything else. Re-running recon or re-testing refuted hypotheses because the prior session's state wasn't checked is the single most wasteful failure mode in a multi-day engagement.

---

## Why this file exists separately from technique knowledge

The domain routers (`web/ROUTER.md`, `api/ROUTER.md`, etc.) answer "what could this be." This file answers "how do I not lose track, not skip steps, and not report noise" — a completely different failure mode than "didn't know the technique." A hunter with encyclopedic technique knowledge and no discipline finds fewer real bugs than a disciplined hunter with a smaller technique library, because the discipline is what prevents wasted effort, missed surface, and false reports. Both matter; this file is the one people skip.
