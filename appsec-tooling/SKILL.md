---
name: appsec-tooling
description: "Capability awareness for a pentest-team operator — a reminder that you can drive the app with a real browser (chrome-devtools MCP / claude-in-chrome), an intercepting proxy (Burp/ZAP, via MCP when connected or the CLI bridge), and a CLI toolbelt, not just raw HTTP; plus the safety rails that extend to any tool. Load it when a finding wants a browser, a proxy, or a scanner. Deliberately thin — it points at capabilities and invariants, not a fixed workflow; how you drive the tools is yours."
---

# AppSec Tooling — what you can reach for

You are not limited to raw requests. When a finding needs more, reach for it — how you drive the tool is your call. This skill just makes sure you know the options exist and that the engagement's safety rails follow the tool.

## You may have more than raw HTTP

The sidecar advertises the tools LIVE on this host in your brief (a "Session tooling" block) and in `.engagement/tooling.json`. PREFER the tools it lists present for the finding classes they fit, rather than reinventing them over raw HTTP — and DECLARE what you hold on the roster / `CONTRACT.md` so peers know who drives what.

Check what this session actually has (`ToolSearch`, or the relevant skill), then use it:

- **A real browser** — chrome-devtools MCP, or the `chrome-devtools-mcp:chrome-devtools` / `claude-in-chrome` skills (they own the mechanics). Reach for it when raw HTTP is awkward: DOM and client-side XSS, multi-step business-logic and auth flows, exact request/response capture, and screenshots for evidence.
- **An intercepting proxy** — Burp or ZAP. If a Burp/ZAP **MCP server is connected**, drive it directly (`ToolSearch("burp")` / `ToolSearch("zap")`). If not, the bridge always works: capture a request and feed the CLI. The human can run Burp interactively on your tmux when a step needs a human. If an MCP tool starts erroring mid-session, the connection has usually dropped, not the tool — reconnect it (`/mcp reconnect`) before you conclude the capability is gone.
- **A CLI toolbelt** — httpx, ffuf/feroxbuster, arjun, sqlmap/ghauri, nuclei, jwt_tool, and whatever else fits. Prefer a request captured through the browser/proxy as input, so the tool tests the same authenticated surface you do.

**Declare what you hold** on the roster or in `CONTRACT.md`, so peers know who can drive a browser and who holds the proxy.

## The safety rails follow the tool

Everything the protocol already requires of a raw request applies to a tool — a page you navigate or a scanner you point *is* a request you sent:

- **Scope** (PROTOCOL §Permissions) — set the tool's target scope to the ROE allowlist *before* you drive it. A browser emits third-party requests by default and a scanner attacks whatever it reaches; unscoped either way is the same incident as a raw out-of-scope request.
- **Isolation** (PROTOCOL §Shared resources) — your own browser context, your own proxy port/project. A shared profile or history clobbers other operators.
- **Do no harm** (PROTOCOL §Permissions) — active scans and Intruder-style fuzzing are heavy and can be destructive; gate them through the anchor for production, and throttle so you don't ban the whole team.

## Feed the vault

Driven flows are the most reusable instruments a team keeps (PROTOCOL §Vault): the auth flow you drive once becomes the app's token minter; a recorded multi-step exploit becomes a replayable instrument; a scanner config tuned to an app becomes per-app tooling. Re-verify them next run — a token minter breaks the moment the app changes its login.
