# IDOR (Insecure Direct Object Reference)

## Attack Surface Signals
- **URL & Routing Patterns**:
  - Direct record identifiers: `/api/v1/users/{id}`, `/api/orders/{id}/download`, `/invoices/{uuid}/pdf`
  - Relationship paths: `/api/orgs/{org_id}/members/{user_id}`, `/api/workspaces/{id}/settings`
  - File downloads & exports: `/export/report?report_id={id}`, `/documents/view?doc_uuid={uuid}`
  - GraphQL queries: `node(id: "gid://app/User/123")`, `query { getInvoice(id: "...") { ... } }`
- **Parameter Names**: `id`, `user_id`, `account_id`, `org_id`, `team_id`, `doc_id`, `uuid`, `order_id`, `tenant_id`, `invoice_no`
- **Frontend / JS Tells**: Hidden form inputs `<input type="hidden" name="user_id" value="123">`, route handlers with unpackaged URL params.

## Step-by-Step Hunting Methodology
1. **Matrix Setup (User A & User B)**:
   - Create two accounts with identical privileges (Tenant A / User A and Tenant B / User B).
   - Create a low-privileged User C if testing vertical privilege escalation.
2. **Harvest Identifiers**:
   - Log all object IDs, UUIDs, numeric keys, and hashes created in User A's session.
3. **Cross-Tenant Access Test**:
   - Replay User A's API requests using User B's authentication headers (`Authorization`, `Cookie`, `X-CSRF-Token`).
   - Check if User B receives `200 OK` with User A's data (read IDOR).
4. **State-Changing Mutation Test**:
   - Send `PUT`, `PATCH`, `DELETE` requests from User B targeting User A's object IDs (write/delete IDOR).
5. **HTTP Verb & Format Tampering**:
   - Swap verbs: `GET` → `POST` / `PUT` / `PATCH` / `DELETE`.
   - Change content types: `application/json` → `application/xml` or `multipart/form-data`.
   - Append extensions: `/api/users/123.json`, `/api/users/123.xml`.

## Payloads & Bypass Techniques
- **Parameter Pollution (HPP)**:
  - `?id=UserB_ID&id=UserA_ID`
  - `?id[]=UserB_ID&id[]=UserA_ID`
  - `{"id": UserB_ID, "id": UserA_ID}` or `{"id": [UserA_ID]}`
- **Header-Based Tenant Swapping**:
  - Modify `X-User-ID: <Victim_ID>`, `X-Account-ID: <Victim_ID>`, `X-Tenant-ID: <Victim_Tenant>`.
  - Spoof gateway routing headers: `X-Original-User-ID`, `X-Forwarded-User`.
- **GUID / Numeric Transformation**:
  - Convert GUID to numeric integer: `/api/user/1` vs `/api/user/00000000-0000-0000-0000-000000000001`.
  - Test wildcard / wildcard array: `{"id": "*"}` or `{"id": true}`.
- **GraphQL Relay Node Traversal**:
  - Extract Global IDs (GID) via base64 decoding (`gid://app/Project/456`).
  - Query generic `node(id: "...")` interface across tenants.

## Common Root Causes
- Object lookups perform direct queries (`SELECT * FROM records WHERE id = ?`) without scoping by session user (`AND user_id = ?`).
- Reliance on client-side hiding or UI-level routing without server-side record ownership validation.
- API gateway verifies authentication token validity but microservices trust raw ID arguments without cross-checking tenant context.

## Exploit Chains
- **IDOR on Profile Update → ATO**: Modifying email/password endpoint accepting `user_id` without verifying existing session context.
- **IDOR on Document Export → Mass Exfiltration**: Iterating numeric `report_id` to bulk-scrape private invoices and PII.
- **IDOR + Soft Delete → Persistent Access**: Revoking an invitation does not invalidate the underlying entity mapping.
