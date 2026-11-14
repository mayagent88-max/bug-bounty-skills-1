---
name: mobile-router
description: Signal table for mobile app (iOS/Android) and thick-client hunting -- what to check first based on platform and app shape.
---

# Mobile & Thick-Client Hunting — Router

> [!NOTE]
> Mobile applications are clients to the same backend APIs evaluated in [`../web/ROUTER.md`](../web/ROUTER.md) and [`../api/ROUTER.md`](../api/ROUTER.md). Always prioritize intercepting backend API traffic over static-only findings. Pure root/jailbreak detection and basic missing cert pinning without backend impact are universally closed as Not Applicable.

Scan this router when testing Android APKs, iOS IPAs, desktop thick clients (Electron / WPF), or web applications utilizing client-side request signing algorithms.

---

## Mobile & Client-Side Signal Table

| Target Shape / Platform | Observable Signals (Artifacts, Manifest, Scheme) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **Android APK (Static)** | `.apk`, `AndroidManifest.xml`, `strings.xml`, `classes.dex` | Decompile with `jadx`; grep for hardcoded API keys (`AKIA...`), unlinked `/api/internal/` endpoints, and Firebase URLs | `references/android.md` |
| **Android Exported Components**| `android:exported="true"`, `<intent-filter>`, custom deep link schemes | Trigger component with `adb shell am start -a android.intent.action.VIEW -d "app://auth?token=..."`; verify unauthorized state change | `references/android.md` |
| **Android Cert Pinning & Traffic**| SSL handshake errors in Burp/mitmproxy, OkHttp `CertificatePinner`, Network Security Config | Hook SSL verification with Frida script (`frida --codeshare pcip/universal-android-ssl-pinning-bypass-with-frida`); verify HTTPS traffic flows | `references/android.md` |
| **iOS IPA (Static & Storage)** | `.ipa`, `Info.plist`, Mach-O binary, `NSAppTransportSecurity`, Universal Links | Extract IPA; inspect `Info.plist` for `NSAllowsArbitraryLoads` and grep binary strings for cloud credentials | `references/ios.md` |
| **iOS Deep Links & IPC** | Custom URL schemes (`CFBundleURLSchemes`), Universal Links (`apple-app-site-association`) | Open Safari on device/simulator and navigate to `customscheme://open?url=http://attacker.com`; verify arbitrary URL open/token leak | `references/ios.md` |
| **iOS Cert Pinning & Keychain** | `NSURLSession`, SecTrustEvaluate, Keychain items, NSUserDefaults | Bypass pinning with Objection (`ios sslpinning disable`); dump decrypted app memory or inspect unprotected SQLite DBs | `references/ios.md` |
| **JS / Client Request Signing** | Headers `X-Signature: hex`, `X-Timestamp`, `X-Nonce`, obfuscated JS, WebAssembly (Wasm) | Trace signature field backward in debugger; isolate input serialization and hash function; replay modified body with recomputed signature | `references/client-reverse.md` |
