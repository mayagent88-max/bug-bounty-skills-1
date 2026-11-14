# Bug Bounty Program Status (Updated 2026-05-12)

## How to Verify a Program is Active

Before investing time on ANY target, verify:

1. **HackerOne**: Visit `hackerone.com/<program>` — look for "Submit a report" button. If it says "taking a break" or "not accepting new submissions" → SKIP.
2. **YesWeHack**: Visit `yeswehack.com/programs/<slug>` or use API: `curl -sL "https://api.yeswehack.com/programs/<slug>"` — 404 means program gone/private.
3. **Direct programs**: Visit the project's SECURITY.md or security page — look for explicit bounty amounts and active submission links.
4. **GitHub SECURITY.md**: Check repo root, `.github/SECURITY.md`, or `docs/SECURITY.md` for bounty links.

**Pitfall**: A program being "on HackerOne" doesn't mean it's accepting submissions. ownCloud had a HackerOne page but was discontinued.

## ✅ CONFIRMED PAYING — PHP Targets (Best for Kanjeng)

| Program | Platform | Bounty Range | Language | Notes |
|---------|----------|-------------|----------|-------|
| **Matomo** | HackerOne | **$777 — $13,000** | PHP | ⭐ TOP RECOMMENDATION. Analytics platform. $13K for Critical (RCE/SQLi), $1,777 for High (XSS/CSRF/auth bypass), $777 other. Repo: `matomo-org/matomo` (21.5K stars). Active, accepting submissions. **AUDIT STATUS**: Deep audit completed 2026-05-12 — well-hardened, see `references/matomo-audit-findings.md`. SSRF confirmed (weak blocklist, VIEW access trigger). **REPORT SUBMITTED** to HackerOne (awaiting response). **NOTE**: Matomo enforces HackerOne Signal requirement (Strict ≥ 1.0) — new users get 4 trial reports per program, 6 total per 30 days. Reference: https://docs.hackerone.com/en/articles/8505319-signal-requirements |
| **Automattic/Jetpack** | HackerOne | $250 — $10,000 | PHP | WordPress ecosystem. Wide scope: Jetpack, WooCommerce, WordPress.com, Tumblr, Day One. Repo: `Automattic/jetpack` (15K+ files monorepo). **AUDIT STATUS**: Recon completed 2026-05-12 — see `references/jetpack-audit-findings.md`. Top findings: Forms Post-to-URL SSRF (no wp_safe_remote), DNS rebinding TOCTOU in webhooks, External Media SSRF. Submit at `hackerone.com/automattic`. |
| **Adobe/Magento** | HackerOne | **$100 — $15,000** | PHP | E-commerce. 3 Tiers verified via GraphQL API (2026-05). Tier 1 (Magento, ColdFusion, Firefly): Critical $5K-$10K. Tier 2 (Commerce Web, Behance, Express): Critical $2.5K-$5K. Tier 3 AI Bonus (Firefly AI, Acrobat AI): Critical $7.5K-$15K. Repo: `magento/magento2` (12K stars, 23K PHP files, 222 modules). `hackerone.com/adobe`. **AUDIT STATUS**: Attack surface analysis completed 2026-05-13 — 41 unauthenticated REST endpoints, GraphQL introspection, SSRF vectors (ProductVideo, Dashboard Tunnel), deserialization points, file upload vectors. See `references/magento-audit-findings.md`. NOT yet cloned for deep audit. |
| **Drupal** | HackerOne | **VDP ONLY** | PHP | CMS. `hackerone.com/drupal`. **No monetary bounties** — VDP only (verified via GraphQL API 2026-05: `offers_bounties: null`). Credit/Hall of Fame only. NOT worth hunting for bounty. |
| **MediaWiki/Wikimedia** | HackerOne | **VDP ONLY** | PHP | Wikipedia's engine. `hackerone.com/mediawiki`. **No monetary bounties** — VDP only (verified via GraphQL API 2026-05: `offers_bounties: null`). Credit/Hall of Fame only. NOT worth hunting for bounty. |

## ✅ CONFIRMED PAYING — Other Languages

| Program | Platform | Bounty Range | Language | Notes |
|---------|----------|-------------|----------|-------|
| Shopware | Own form | EUR (varies) | PHP/Symfony | shopware.com/en/contact/security-reporting |
| GitLab | HackerOne | $1K — $30K | Ruby | Very competitive. |
| Discourse | HackerOne | $256 — $2,048 | Ruby | Forum platform. **⚠️ BOUNTIES SUSPENDED** as of Feb 2026 (due to AI report flood). Will review in 60 days. May accept reports but no guaranteed payment. |
| 1Password | HackerOne | Varies | Go/Rust | Password manager. |
| Internet Bug Bounty | HackerOne | $500 — $15K | Various | Covers FOSS infrastructure. |

### YesWeHack Programs (66+ with bounties, confirmed via API)

**Top by bounty:**
| Program | Max Bounty | Country |
|---------|-----------|---------|
| Swiss Post E-Voting | €230,000 | CH |
| Doctolib | €50,000 | FR |
| Tchap (French Gov) | €20,000 | FR |
| FDJ United | €15,000 | SE |
| OVHcloud | €12,500 | FR |
| TeamViewer | €10,000 | DE |
| Swiss Post | €10,000 | CH |

**Indonesian programs (relevant for Kanjeng):**
| Program | Max Bounty | Reports |
|---------|-----------|---------|
| GoTo Financial | $7,000 | 491 |
| GOJEK | $5,000 | 583 |
| DANA | $3,000 | 204 |

**Low-competition YesWeHack programs (fewer reports = easier to find bugs):**
| Program | Max Bounty | Reports | Country |
|---------|-----------|---------|---------|
| Xelians | €1,500 | 67 | FR |
| Dossier Medical Partagé | €2,000 | 82 | FR |
| DataDome Bot Bounty | €3,000 | 90 | FR |
| Moneybox | €2,000 | 96 | GB |
| Memento | $4,000 | 113 | SG |
| Thüringer Aufbaubank | €7,000 | 123 | DE |
| Okto | $2,000 | 128 | IN |
| GRW Trading | €3,000 | 136 | AE |
| BitOasis | $2,000 | 186 | IN |
| Harman Lifestyle | $4,000 | 204 | US |
| Cryptobox | €5,000 | 279 | FR |
| Mon Espace Santé | €8,000 | 289 | FR |

**YesWeHack API for program discovery:**
```bash
curl -sL "https://api.yeswehack.com/programs?paginated=true&page=1&itemsPerPage=100"
```

Response: `items[]` with `title`, `slug`, `status`. Note: `bounty_range` field may be empty in API — check individual program pages for actual amounts.

## ❌ CONFIRMED NOT PAYING / PAUSED / DISCONTINUED

| Program | Status | Reason |
|---------|--------|--------|
| **ownCloud** | ⚠️ UNCLEAR | HackerOne: `offers_bounties: true`, 294 resolved reports, but no public bounty table. May pay but amounts unknown. Verify before investing time. |
| **Nextcloud** | ❌ SUSPENDED | Suspended monetary bounties (2026) due to AI-generated report flood. |
| **PrestaShop** | ⏸️ PAUSED | YesWeHack program paused. SECURITY.md says "currently paused, report to security-core@prestashop.com instead". |
| Saleor | ❌ No rewards | "No monetary rewards" in SECURITY.md |
| Strapi | ❌ No rewards | "No bounties, no swag" |
| Rocket.Chat | ❌ No rewards | "No monetary rewards" |

## ⚠️ PAYMENT UNCERTAIN (verify before investing)

| Program | Notes |
|---------|-------|
| Bagisto | Accepts reports via email, no explicit bounty mentioned |
| Crater | security@craterapp.com, no bounty info |
| Invoice Ninja | contact@invoiceninja.com, no bounty info |
| Snipe-IT | security@snipeitapp.com, credit only? |
| Cal.com | security@cal.com, no explicit bounty |
| Payload CMS | security@payloadcms.com, no explicit bounty |
| MedusaJS | security@medusajs.com, no explicit bounty |
| Appwrite | security@appwrite.io, no explicit bounty |

## HackerOne API Notes

HackerOne's web pages are behind Cloudflare JS challenge, BUT the **GraphQL API is accessible**:
```bash
curl -sL 'https://hackerone.com/graphql' -X POST -H 'Content-Type: application/json' \
  -d '{"query":"{ team(handle: \"PROGRAM\") { name offers_bounties bounty_table { bounty_table_rows { nodes { critical critical_minimum high high_minimum medium medium_minimum low low_minimum use_range } } } } }"}'
```
- `offers_bounties: null` = VDP only (no money)
- `offers_bounties: true` = paid bounty program
- Schema introspection works — see `references/hackerone-graphql-api.md`
- No auth required for public program data

## Tips
- Always check the program page directly before investing time
- "Bug bounty program" in description ≠ guaranteed payment
- Look for explicit reward amounts or "monetary rewards" language
- HackerOne programs with "bounty" in title usually pay
- Direct-to-email programs often only give credit
- **Verification script**: Before cloning a repo, run: `curl -sI "https://hackerone.com/<program>" | head -5` to check if the page loads
- **HackerOne Signal Requirement**: Some programs enforce a "Signal" metric (see https://docs.hackerone.com/en/articles/8505319-signal-requirements). Signal measures report quality on a rolling 365-day window. Levels: Strict (≥ 1.0), Standard (≥ 0.0), Lenient (≥ -1.0). **Trial report limits** (rolling 30-day window): New hackers (< 5 resolved reports): 4 per program, 6 platform total. Seasoned hackers: 8 per program, 12 platform total. **Signal impact**: Accepted = UP, Informational/Duplicate = NEUTRAL, Rejected/Spam = DOWN. This was encountered on the Matomo program (2026-05-12). Warn user before submitting — only submit reports you're confident are valid.
