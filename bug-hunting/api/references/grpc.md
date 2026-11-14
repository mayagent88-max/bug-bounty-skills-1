# gRPC & Protobuf Hunting Reference

## Attack Surface Signals
- **Wire Format**: HTTP/2 transport with `content-type: application/grpc`, `application/grpc+proto`, `application/grpc-web+proto`.
- **Common Ports**: `50051`, `50052`, `9090`, `8080`, `443`.
- **Framing**: Binary protobuf payloads with 5-byte gRPC frame prefix (`[1-byte compression flag][4-byte big-endian length]`).
- **Error Headers**: `grpc-status: 0` (OK), `grpc-status: 7` (PERMISSION_DENIED), `grpc-status: 16` (UNAUTHENTICATED), `grpc-message: ...`.

## Reconnaissance & Schema Discovery
1. **Server Reflection Enumeration**:
   - Test if gRPC Server Reflection is enabled:
     `grpcurl -plaintext <target>:50051 list`
     `grpcurl -plaintext <target>:50051 describe <package.ServiceName>`
   - Dump all services and proto definitions:
     `grpc_cli ls <target>:50051 -l`
2. **Proto File & Symbol Extraction (Without Reflection)**:
   - Extract embedded protobuf descriptor symbols from compiled mobile apps (APK/IPA) or web binaries using `protoc --decode_raw` or `strings <binary> | grep -E '\.proto'`.
   - Reconstruct `.proto` definitions to construct valid requests.

## Attack Techniques & Methodology
1. **Unauthenticated Method Invocations**:
   - Replay service calls with empty auth metadata:
     `grpcurl -plaintext -d '{"user_id": "1"}' <target>:50051 package.UserService/GetUser`
   - Test internal / debug services discovered via reflection (e.g. `admin.AdminService/ExecuteCommand`, `health.Health/Check`).
2. **Metadata & Header Trust Spoofing**:
   - Inject spoofed gateway headers into gRPC metadata:
     `grpcurl -H "x-forwarded-user: admin" -H "x-user-role: superadmin" ...`
   - Downstream microservices often trust metadata without re-verifying HMAC/JWT tokens.
3. **gRPC-Web & Gateway Transcoding Attacks**:
   - Applications exposing REST endpoints converted to gRPC via `grpc-gateway` or `envoy`:
     - Test path parameter injection and URL decoding anomalies (`/v1/users/{id}` where `id` contains encoded protobuf fields).
     - Test HTTP method switching and verb tunneling.
4. **Protobuf Deserialization & Type Confusion**:
   - Inject unexpected wire types (e.g. string where int is expected) to trigger backend panic or uncaught exception.
   - Test recursive message depth limits to cause Denial of Service.
5. **HTTP/2 Stream Reset DoS (Rapid Reset)**:
   - Send stream of `HEADERS` frames immediately followed by `RST_STREAM` over multiplexed HTTP/2 connection.

## Exploit Chains
- **Server Reflection Enabled → Internal Admin Service Discovery → Unauthenticated Pre-Auth Method Execution**.
- **Metadata Header Spoofing → Microservice Trust Boundary Bypass → Tenant Data Takeover**.
