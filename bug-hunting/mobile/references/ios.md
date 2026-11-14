# iOS Security & IPA Red Team Reference

## IPA Unpacking & Static Analysis
1. **Extraction & Binary Analysis**:
   - Unpack IPA: `unzip target.ipa -d ipa_unpacked/`
   - Navigate to app bundle: `cd ipa_unpacked/Payload/*.app`
   - Inspect `Info.plist` with `plutil -p Info.plist`.
   - Decrypt FairPlay-encrypted Mach-O binary on jailbroken device using `frida-ios-dump` or `bagbak`.
2. **App Transport Security (ATS) Misconfigurations**:
   - Check `Info.plist` for `NSAppTransportSecurity`:
     `<key>NSAllowsArbitraryLoads</key><true/>` (Allows plaintext HTTP traffic across all endpoints).
3. **Static Secret Scraping in Mach-O**:
   - `strings <AppName> | grep -E '(https?://|AKIA[0-9A-Z]{16}|bearer )'`

## URL Schemes & Universal Links
1. **Custom URL Schemes**:
   - Find schemes in `Info.plist` under `CFBundleURLTypes` -> `CFBundleURLSchemes`.
   - Test invoking custom URL schemes via Safari on iOS device:
     `targetscheme://action?param=value`
2. **Universal Links (`apple-app-site-association`)**:
   - Fetch `https://target.com/.well-known/apple-app-site-association`.
   - Verify path handlers in app binary for unsafe parameter reflection or token exposure.

## Dynamic Instrumentation with Objection & Frida
1. **SSL Pinning Bypass via Objection**:
   - Launch app on jailbroken iOS device connected via USB:
     `objection --gadget "AppName" explore`
   - Disable pinning:
     `ios sslpinning disable`
2. **Insecure Local Storage & Keychain Inspection**:
   - Dump user defaults: `ios nsuserdefaults get`
   - Inspect plist files in `/var/mobile/Containers/Data/Application/<UUID>/Library/Preferences/`.
   - Dump Keychain items: `ios keychain dump` (Check for plaintext passwords, tokens, or encryption keys).

## Exploit Chains
- **Custom URL Scheme Parameter Injection → XSS in Embedded WKWebView → Session Hijacking**.
- **Insecure Storage of Master Encryption Key in NSUserDefaults → Local App Data Decryption**.
