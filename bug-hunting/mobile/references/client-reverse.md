# Client-Side Reverse Engineering & Request Signer Recovery Reference

## The Core Principle: Packet-First Reversing
- Never attempt to deobfuscate an entire client application. Reverse ONLY the minimal code path responsible for calculating the custom signature header (e.g. `X-Sign`, `X-Signature`, `X-Token`, `X-Hash`).

## Step-by-Step Signer Recovery Workflow
1. **Locate Signature Field**:
   - Search source files / DevTools sources for exact header name:
     `grep -rn "X-Signature" .` or search in Chrome DevTools Network -> Initiator call stack.
2. **Identify Hash & Signature Function**:
   - Trace backwards from `xhr.setRequestHeader("X-Signature", sig)`:
     ```javascript
     const timestamp = Date.now();
     const nonce = Math.random().toString(36).substring(2);
     const payload = method + path + timestamp + nonce + JSON.stringify(body);
     const sig = CryptoJS.HmacSHA256(payload, secretKey).toString();
     ```
3. **Extract Inputs & Constants**:
   - Identify secret salt / API key constant (often hardcoded or derived from session initialization token).
   - Identify exact string serialization order (e.g. `METHOD + PATH + SORTED_PARAMS + BODY + SECRET`).
4. **JavaScript Deobfuscation & AST Simplification**:
   - If code is obfuscated with Obfuscator.io / Webpack:
     - Use `webcrack` or `de4js` to decode string arrays, hex literals, and control-flow flattening.
     - Isolate cryptographic signing functions into standalone Node.js script.
5. **Construct Replay Harness in Python**:
   ```python
   import hmac, hashlib, time, json, requests

   def sign_request(method, path, body, secret):
       ts = str(int(time.time() * 1000))
       payload = f"{method}{path}{ts}{json.dumps(body, separators=(',', ':'))}"
       sig = hmac.new(secret.encode(), payload.encode(), hashlib.sha256).hexdigest()
       return {"X-Signature": sig, "X-Timestamp": ts}
   ```
6. **Fuzz Protected APIs**:
   - Integrate signing function directly into Burp Extender / Python script to fuzz parameters without triggering `403 Signature Invalid` errors.

## Exploit Chains
- **Reconstructed Request Signer → Automated API Fuzzing → IDOR / Remote Code Execution on Backend API**.
