# Bug Bounty 8-Phase Workflow

Use this skill when the user asks you to work a bug bounty program, such as a YesWeHack, HackerOne or Immunefi program. Work the phases in order and stop when a phase shows the target is out of scope, untestable or not worth a report.

This is Maya's own 8-phase version, built 6 Nov 2026 because the original bb-boss-workflow file lives in another agent (Lexy in the user's screenshot) and is not available to copy. It follows the standard professional bug bounty flow, not that agent's exact file.

## Phase 1 Scope and rules

- Read the program page first and write down what is in scope, what is out of scope, the reward table, the disclosure rules and any testing limits before you touch the target.

- Do not test anything outside the stated scope. A finding on an out-of-scope asset is not payable and can get the account banned.

- Record the program URL, the scope list and the reward table in the working notes for this hunt.

## Phase 2 Passive recon

- Gather public information without sending requests to the target where possible, using the program page, public docs, DNS records, certificate transparency and archived URLs.

- Build a list of domains, subdomains and services that belong to the target, then keep only the ones the scope allows.

- If the target shows no interesting signals after a short passive pass, say so and do not burn time on active scanning yet.

## Phase 3 Asset discovery and fingerprinting

- Check which assets from Phase 2 are live, what status they return and what technology they run, using `browser.browse` for web checks and `muse.exec` with `curl` for quick read-only header and status checks.

- Keep a short list of live web apps with their status, title and stack, and drop dead hosts from the hunt.

- Never run a heavy scanner against a live target without checking the program rules first, because some programs forbid automated scanning.

## Phase 4 Vulnerability scanning

- Run light, read-only checks for known exposures first, such as missing security headers, exposed files, open directories, outdated software banners and subdomain takeover signals.

- Treat every scanner hit as a lead, not a finding. A scanner name alone never proves a payable bug.

- Log each lead with the URL, the evidence seen and the next manual test, so nothing is lost between phases.

## Phase 5 Manual hunting

- Test the live apps by hand for business logic, authentication, authorization, input handling and session flaws, starting with the highest-value flows such as login, payment, account settings and API endpoints.

- Prioritize flaws that change data, move money, expose other users or bypass access control over cosmetic issues.

- If a manual test needs an account, use only an account the user owns or the program provides, and never test with another person's data.

## Phase 6 Proof of concept

- Build a minimal, non-destructive proof of concept that reproduces the flaw on the in-scope target, with exact steps, requests and screenshots or logs.

- Do not exfiltrate real user data, do not delete or modify other users' data, and do not run a destructive exploit. Stop the test as soon as the impact is proven.

- If the flaw cannot be reproduced cleanly, drop it and move on instead of forcing a report.

## Phase 7 Impact and severity

- Score the finding by real impact, not by vulnerability name, using the program's own severity table where one exists.

- Write down who is affected, what an attacker can actually do, how hard it is to exploit and what the business cost is, in plain language the program team can act on.

- Drop Low and informational findings unless the program explicitly pays for them, because a weak report costs more time than it earns.

## Phase 8 Report and follow up

- Submit only through the program's official channel, with a clear title, the affected asset, the reproduction steps, the proof of concept, the impact and a suggested fix.

- Keep the report short and factual, with no exaggerated severity and no out-of-scope claims.

- Track the report status, answer triage questions promptly and retest only when the program asks for a retest or marks the fix as ready.

## Hard limits

- Work only on programs the user names, only on in-scope assets, and only with non-destructive testing.

- Never test a target without a public bug bounty program or written authorization, never attack infrastructure outside the program, and never submit a report you have not reproduced.

- A bounty is paid only when the program validates the finding, so never promise the user a reward amount before triage.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Websites

- [YesWeHack](https://yeswehack.com/) for bug bounty programs and their scope and reward pages. Carry the program URL into the browser task and verify the scope there.

- [HackerOne](https://hackerone.com/) for bug bounty programs and disclosed reports to learn from.

- [Immunefi](https://immunefi.com/) for smart contract and Web3 bug bounty programs.

## Alternatives for better results

- Learn from disclosed reports on the same target or the same bug class before hunting, because a known pattern is faster to test than a blind scan.

- Hunt one high-value flow deeply instead of scanning many shallow pages, because manual business logic flaws pay more than automated scanner hits.
