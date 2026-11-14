---
name: api-router
description: Signal table for API/GraphQL/gRPC/WebSocket hunting -- protocol-specific attack surface and confirmation methods.
---

# API & Protocol Hunting — Router

> [!NOTE]
> Standard web vulnerability classes (IDOR/BOLA, SQLi, SSRF, Auth Bypass, Command Injection, Mass Assignment) apply heavily to modern APIs. For non-protocol-specific vulnerabilities on API endpoints, refer to [`../web/ROUTER.md`](../web/ROUTER.md).

Scan this router when testing API gateways, microservices, SPA backends, mobile APIs, and alternative protocol handlers (GraphQL, gRPC, WebSocket). Match observable indicators to the protocol class and confirm behaviorally before loading reference depth.

---

## Protocol & API Surface Signal Table

| Protocol / Pattern | Observable Signals (URL, Headers, Wire Format) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **GraphQL** | `/graphql`, `/api/graphql`, `/v1/graphql`, `{"query":"..."}`, `__schema`, `__typename` | Send `{__typename}` or full introspection query; verify schema returns types/mutations or field suggestions leak | `references/graphql.md` |
| **Fintech GraphQL** | Mutations: `transferFunds`, `createPayout`, `applyDiscount`, `exchangeCurrency`, `trade` | Replay batch mutation with negative amounts or concurrent single-packet race; verify double-spend/credit | `references/graphql.md#fintech-graphql-specifics` |
| **gRPC & Protobuf** | `content-type: application/grpc`, HTTP/2 frames, binary protobuf payloads, ports 50051/9090 | Probe with `grpc_cli ls host:port` or `grpcurl`; verify Server Reflection returns service/method catalog | `references/grpc.md` |
| **gRPC-Web & Gateway** | `content-type: application/grpc-web+proto`, `/v1/*` transcoding to gRPC microservices | Replay transcode requests without metadata auth headers; verify internal gRPC service executes method | `references/grpc.md` |
| **WebSocket** | `Upgrade: websocket`, `Connection: Upgrade`, `Sec-WebSocket-Key`, `ws://`, `wss://` | Send cross-origin handshake from HTML/JS (`new WebSocket("wss://...")`); verify connection opens without token check (CSWSH) | `references/websocket.md` |
| **Socket.IO / SignalR** | `/socket.io/?EIO=4`, `/hub/`, event messages `42["join_room", {...}]` | Emit unauthorized room subscription or event mutation (`join_channel`, `admin_msg`); verify event fires | `references/websocket.md` |
| **Shadow & Zombie APIs**| `/api/v1/` vs `/api/v2/`, unlinked OpenAPI/Swagger specs, legacy route prefixes, dev docs | Send old schema payload to deprecated version route (`/api/v1/user`); verify deprecated route executes without 2FA/WAF | `references/shadow-api.md` |
| **SPA Backend APIs** | `__NEXT_DATA__`, chunk `.js` bundles with `/api/internal/`, API keys in client code | Extract all hidden API endpoints from unpacked JS routes; test unauthenticated direct access via curl | `references/spa-api.md` |
| **API Misconfigurations**| OData queries (`$filter`, `$select`, `$expand`), OpenAPI `/v3/api-docs`, NSwag, CORS | Submit `$filter=contains(password,'a')` or fetch exposed `/v2/swagger.json`; verify schema/spec or DB filter leak | `references/api-misconfig.md` |
| **Recon / 404 Baseline**| Custom 404 vs gateway 404, wildcard routing, dynamic dispatch, reverse proxy frontends | Request non-existent paths (`/404_canary_xyz`); baseline exact status, content-length, and headers before fuzzing | `references/dispatch.md` |
