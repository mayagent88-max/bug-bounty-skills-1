# YesWeHack Programs (Research from 2026-05-13)

## API Endpoint
`https://api.yeswehack.com/programs?page=1&results_per_page=100`

Response includes: `bounty`, `bounty_reward_min`, `bounty_reward_max`, `currency`, `reports_count`

## Indonesian Programs (High Priority for Kanjeng)

| Program | Bounty Range | Reports | Slug |
|---------|-------------|---------|------|
| **GOJEK** | $5-$5,000 | 590 | gojek-bug-bounty-program |
| **GoTo Financial** | $5-$7,000 | 494 | goto-financial-public-bounty-program |

Both are operated by PT GoTo Gojek Tokopedia Tbk (Indonesia).

## High-Value Programs

| Program | Bounty Range | Reports | Country | Slug |
|---------|-------------|---------|---------|------|
| **Swiss Post E-Voting** | €100-€230,000 | 1,159 | CH | swiss-post-evoting |
| **Doctolib** | €0-€50,000 | 1,513 | FR | doctolib-public-bug-bounty-program |
| **Swiss Post** | €50-€10,000 | 2,213 | CH | swiss-post |
| **TeamViewer** | €100-€10,000 | 721 | DE | teamviewer-bounty-program |
| **Telenor Sweden** | €50-€5,000 | 1,445 | SE | telenor-sweden-public-bug-bounty-program |
| **Louis Vuitton** | €50-€5,000 | 507 | FR | louis-vuitton-malletier-public-bug-bounty-program |
| **HARMAN International** | $100-$4,000 | 1,795 | US | harman-international-web-applications |
| **MediaMarktSaturn** | €100-€4,000 | 437 | DE | mediamarktsaturn-bug-bounty-program |
| **SNCF Connect** | €0-€10,000 | 378 | FR | bug-bounty-sncf-connect-1 |
| **BlaBlaCar** | €50-€3,000 | 1,110 | FR | bug-bounty-program-blablacar |
| **VINCI SA** | €50-€3,000 | 491 | FR | vincisa-public-program |
| **Louis Vuitton** | €50-€5,000 | 507 | FR | louis-vuitton-malletier-public-bug-bounty-program |
| **DataDome** | €50-€3,000 | 437 | FR | datadome-bug-bounty |
| **ExpressVPN** | $50-$2,500 | 464 | IM | expressvpn-bug-bounty-program |
| **Cryptobox** | €100-€5,000 | 280 | FR | cryptobox-bug-bounty |
| **Ezviz** | $0-$5,000 | 636 | CN | ezviz-bug-bounty-program |
| **BookBeat** | €50-€2,000 | 482 | SE | bookbeat |

## Low-Competition Strategy

Use API to find programs with <300 reports. Fewer reports = fewer hunters = higher chance of finding unreported bugs.

```bash
curl -s 'https://api.yeswehack.com/programs?page=1&results_per_page=100' | jq '.items[] | select(.bounty==true) | {title, reports_count, bounty_reward_min, bounty_reward_max}' | jq -s 'sort_by(.reports_count)'
```

## YesWeHack vs HackerOne

| Aspect | YesWeHack | HackerOne |
|--------|-----------|-----------|
| Signal system | ❌ No | ✅ Yes (strict programs) |
| Indonesian programs | ✅ GOJEK, GoTo | ❌ Fewer |
| Competition | Lower (Europe-focused) | Higher (global) |
| KYC required | Yes (verified hunters) | No |
| API access | Public | GraphQL (requires auth for some) |
