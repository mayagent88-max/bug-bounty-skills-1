# HackerOne GraphQL API

HackerOne's GraphQL endpoint is publicly accessible at `https://hackerone.com/graphql` — bypasses Cloudflare bot protection that blocks normal page scraping.

## Key Discovery (2026-05-13)

HackerOne's web pages are behind CF JS challenge, but the GraphQL API accepts POST requests from curl with no auth required for public program data.

## Bounty Table Query

Query exact bounty ranges for any program:

```bash
curl -sL 'https://hackerone.com/graphql' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"query":"{ team(handle: \"MATOMO_HANDLE\") { name offers_bounties bounty_table { description bounty_table_rows { nodes { name description critical critical_minimum high high_minimum medium medium_minimum low low_minimum use_range structured_scope { asset_identifier asset_type } } } } } }"}'
```

Replace `MATOMO_HANDLE` with the program handle (e.g., `adobe`, `matomo`, `automattic`).

## Schema Introspection

Discover available types and fields:

```bash
# List BountyTable fields
curl -sL 'https://hackerone.com/graphql' -X POST -H 'Content-Type: application/json' \
  -d '{"query":"{ __type(name: \"BountyTable\") { name fields { name type { name kind ofType { name } } } } }"}'

# List BountyTableRow fields
curl -sL 'https://hackerone.com/graphql' -X POST -H 'Content-Type: application/json' \
  -d '{"query":"{ __type(name: \"BountyTableRow\") { name fields { name type { name kind ofType { name } } } } }"}'
```

## Key Schema Types

### BountyTable
- `bounty_table_rows` → BountyTableRowConnection
- `description` → String (program-specific bounty notes)
- `critical_label`, `high_label`, `medium_label`, `low_label` → String

### BountyTableRow
- `critical`, `critical_minimum` → Int (max/min for Critical severity)
- `high`, `high_minimum` → Int
- `medium`, `medium_minimum` → Int
- `low`, `low_minimum` → Int
- `use_range` → Boolean (true = min-max range, false = fixed amount)
- `structured_scope` → { asset_identifier, asset_type } (e.g., "Tier 1", "Tier 3 (AI Bonus Tier)")
- `description` → String
- `name` → String

### Team
- `name`, `handle` → String
- `offers_bounties` → Boolean (null = VDP only, true = has bounties)
- `bounty_table` → BountyTable
- `resolved_report_count` → Int (total resolved reports — gauges program activity/competition)

## VDP vs Bounty Distinction

- `offers_bounties: null` + `bounty_table: null` = **VDP only** (no monetary rewards)
- `offers_bounties: true` + bounty_table with rows = **Paid bounty program**

Known VDP-only programs (no money):
- Drupal (`drupal`)
- MediaWiki (`mediawiki`)

## Python Helper

```python
import json
from hermes_tools import terminal

def query_bounty(handle):
    query = json.dumps({
        "query": f'{{ team(handle: "{handle}") {{ name offers_bounties bounty_table {{ description bounty_table_rows {{ nodes {{ name description critical critical_minimum high high_minimum medium medium_minimum low low_minimum use_range structured_scope {{ asset_identifier asset_type }} }} }} }} }} }}'
    })
    result = terminal(f"curl -sL 'https://hackerone.com/graphql' -X POST -H 'Content-Type: application/json' -d '{query}'")
    return json.loads(result["output"])

# Usage:
data = query_bounty("adobe")
team = data["data"]["team"]
if team.get("offers_bounties"):
    for row in team["bounty_table"]["bounty_table_rows"]["nodes"]:
        scope = row.get("structured_scope", {}).get("asset_identifier", "Unknown")
        print(f"{scope}: Critical ${row['critical_minimum']}-${row['critical']}, High ${row['high_minimum']}-${row['high']}")
else:
    print(f"{team['name']}: VDP only, no monetary bounties")
```

## Pitfalls

- **Rate limiting**: Unknown — don't spam requests. Batch queries if possible.
- **Auth required for private programs**: Only public program data is accessible without auth.
- **Field names are case-sensitive**: `BountyTable` not `bountyTable`.
- **Null handling**: `offers_bounties` can be `null` (not `false`) for VDP programs. Check with `is None` in Python.
- **No search endpoint**: Can't search programs by keyword via GraphQL. Use known handles.
- **Bulk scanning technique**: To discover which programs have bounties, loop through a list of known handles and check `offers_bounties` for each. Most PHP open-source projects return `null` (VDP only). Found 80+ handles scanned in ~30 seconds with 50 queries per batch. See SKILL.md "PHP Open-Source Bounty Landscape" section for results.
- **resolved_report_count**: Adobe has 8,611 resolved reports but that's ALL Adobe products (Photoshop, Acrobat, etc.), not just Magento. Matomo has 269 reports specific to Matomo. Don't compare these directly — Adobe's number includes many non-PHP products.
