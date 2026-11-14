# Chromium Control

Drive pure open-source Chromium on this VM with Playwright. Never use Google Chrome for this. The Google Chrome product (`google-chrome-stable`) is a different browser and the user does not want it. Chromium here means the unbranded open-source build whose `--version` prints `Chromium 159.0.8153.0` with no Google in the name.

## What is installed

- Playwright 1.65.0 and `@playwright/mcp` 0.0.84 live in `~/workspace/chromium-control/` (`package.json`, `node_modules`). Node v24 is required and already present.

- Pure Chromium snapshot rev 1738879 lives at `~/workspace/chromium-control/chromium-pure/chrome-linux/chrome` and prints `Chromium 159.0.8153.0`. Keep it under the home directory so it survives VM restarts. Never install `google-chrome-stable` to satisfy this skill.

- Playwright also ships its own Chromium build in `~/.cache/ms-playwright/chromium-1254/`, but that binary prints `Google Chrome for Testing`, so prefer the pure snapshot above for anything the user sees. Use the Playwright build only as a fallback when the pure binary is missing.

- The proxy forwarder lives at `~/workspace/chromium-control/local-proxy.js`. It listens on `127.0.0.1:18080` and adds preemptive proxy authorization for the VM egress proxy. It reads credentials from the environment at runtime and never writes them to any file.

## Launch Chromium

- Start the forwarder first in the background, then run the Playwright script. Kill the forwarder when the work is done.

- Launch with an explicit binary and the local proxy. Headless is the default on this VM because there is no display. Pass `--ignore-certificate-errors` because the VM egress proxy terminates TLS with its own certificate, the same flag the earlier Chrome setup needed.

```js
const { chromium } = require('playwright');
const browser = await chromium.launch({
  executablePath: '/home/hatch/workspace/chromium-control/chromium-pure/chrome-linux/chrome',
  headless: true,
  args: ['--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--proxy-server=http://127.0.0.1:18080', '--ignore-certificate-errors'],
});
```

- A ready-made check lives at `~/workspace/chromium-control/verify-chromium.js`. Run it with `node verify-chromium.js [url]` while the forwarder runs. It prints the browser version, the final URL and the page title, and saves a screenshot to `verify-chromium.png`.

- Keep the browser profile inside the workspace when a task needs a persistent session, for example `~/workspace/chromium-control/profile/`. Profiles under `/tmp` vanish on VM restart.

## Drive a page

- Use the accessibility snapshot style: `page.goto`, `page.locator`, `page.click`, `page.fill`, `page.screenshot`. Wait for `domcontentloaded` first, then wait for the element you need instead of sleeping a fixed time.

- Read text with `page.title()` and `page.evaluate(() => document.body.innerText)` when a check needs the visible text. Save screenshots with `page.screenshot` and read them back with `muse.read` before describing what the page shows.

- Never invent a URL. Use only a URL the user gave, one a tool returned, or a well-known address you are sure of.

## Limits learned on this VM

- X (x.com) blocks this VM's datacenter egress IP with HTTP 403 or a login refusal, in every browser here. That is an X-side IP block, not a browser problem. Google and the Chrome Web Store load fine in the same Chromium, which proves the browser and the network work.

- Chromium cannot send proxy authentication on a CONNECT request by itself, so direct `--proxy-server` with credentials fails. Always go through `local-proxy.js`.

- The VM is replaced from time to time. Anything installed outside the home directory disappears, including system packages and `/tmp`. Reinstall from the workspace copies when a binary goes missing, and keep the pure Chromium zip beside the extracted copy if disk allows.

- Do not use the managed Muse browser for work this skill covers. That browser is a separate product the user can take over, and its toolbar and `chrome://` pages are not reachable from here. Drive the local Chromium instead.

## Playwright MCP server

- `@playwright/mcp` is installed alongside Playwright for MCP clients that need a persistent browser session. Start it with `npx @playwright/mcp@latest` and point it at the pure binary when the client supports a browser path, otherwise it uses Playwright's own Chromium build.

- For one-off work from this agent, prefer a Playwright script over the MCP server. Scripts are shorter, deterministic, and do not need a client configuration.

## CookieJar (ungu) — installed + verified 9 Nov 2026

- The extension the user uses on his phone: **"CookieJar — Cookie Backup & Restore"** (ID `dhpchmenbdolbceedfegjgmdfaidmfbk`, v1.0.0, by cwsbuilderslab). Dark navy/purple popup. NOT the other "Cookie Manager & Editor - CookieJar" (ktg0215).
- **Getting the CRX:** the Chrome Web Store UI install fails in this Chromium (a "Switch to Chrome?" dialog blocks it) and `clients2.google.com` is proxy-403, but **crx4chrome.com works**: `https://www.crx4chrome.com/search.php?s=<extension-id>` redirects to a downloader page with a direct CRX link on `clients2.googleusercontent.com` (different host, reachable). Downloaded 9 Nov: 20,885 bytes, CRX3.
- **AUDITED CLEAN before loading:** manifest v1.0.0, permissions `cookies` + `downloads` only, `host_permissions <all_urls>`; popup.js is fully local (chrome.cookies getAll/set, chrome.downloads, FileReader) — zero fetch/XHR/WebSocket/analytics; import accepts only its own `format: "cookiejar"` exports. Unpacked at `~/workspace/chromium-control/extensions/cookiejar-backup-restore/` (keep the `cookiejar.crx` beside it).
- **Loading an unpacked extension:** Playwright adds `--disable-extensions` by default — pass `ignoreDefaultArgs: ['--disable-extensions']` and launch with `--load-extension=<dir>` + `--disable-extensions-except=<dir>` (headed via `xvfb-run -a`). The extension ID for an unpacked extension is derived from its absolute path (SHA256, first 16 bytes mapped to a–p): for this path it is `aanmpkhagnabbhckjpddbcpckildhnnp`, so its popup is `chrome-extension://aanmpkhagnabbhckjpddbcpckildhnnp/src/popup.html`.
- **Verify by opening the popup page directly** (HTTP 200 + UI text + screenshot). Do NOT trust `chrome://extensions` innerText (shadow DOM → empty text) or the profile's `Extensions/` folder (unpacked extensions are referenced by path, not copied there). Verified 9 Nov: popup renders the purple Export/Import UI; script `~/workspace/chromium-control/verify-cookiejar.js`, screenshot `cookiejar-popup.png`.
- **Limitation that remains:** the user's X cookie JSON was deleted 9 Nov per his "hapus semua" order — importing X cookies again needs a fresh export from his phone. And even with valid cookies, X may still 403 this VM's IP.

## Safety

- Never sign in to any account, fill a password, or import cookies, keystores, or session files through this Chromium unless the user explicitly asked for that exact step in this conversation.

- Never write proxy credentials, passwords, keys, or cookie values into any file, including scripts and logs. Read them from the environment at runtime only.

## Mengelola X @akunata82 (tumbuhkan akun, aman dulu)

Mandat Madi 9 Nov 2026 ~17:39: Maya bebas ngurus akun X @akunata82 agar maksimal — post, reply, like, follow, bio, pin. Batas aman dari perintah 17:30 ("jangan membabi buta... agar akun aman") TETAP berlaku dan mengikat mandat ini.

**Baseline (audit 9 Nov ~17:31):** 44 followers, 513 following, 642 posts, bio lama `J8837K5C just me!!!! 29N6BEMU $FAN Maxi` + blogspot, join Aug 2011, belum Premium.

**Batas harian (keras, jangan dilanggar):**
- Post: max 2–3/hari, tiap post beda isi, ≤280 karakter, tanpa spam link.
- Like: max ~10/hari. Reply: max ~5/hari, isinya nyambung dan ngebantu, bukan "nice" doang.
- Follow baru: max 3–5/hari, hanya akun relevan (crypto/airdrop/Elysium/IPX). Skip iklan dan post sendiri.
- Jeda menit antar aksi (script like pakai 20–30 dtk; antar sesi beri jeda lebih lama).
- LARANGAN: unfollow massal, beli followers, bot/otomatisasi borongan, teks duplikat, follow/unfollow cycle.

**Pola konten yang terbukti (ALFRED/IPX):** cerita personal + tips yang ngebantu fan lain, bukan pengumuman/pamer rank.

**Teknis:**
- Satu browser per profil: JANGAN jalankan dua script Chromium bersamaan di `profile-cookiejar` (profile lock). Tunggu satu selesai sebelum mulai yang lain.
- X lewat proxy lambat: `waitUntil: 'domcontentloaded'` + `waitForSelector` timeout panjang (90–120 dtk). `networkidle` TIDAK PERNAH tercapai di X (koneksi streaming) — jangan pakai.
- Script: `x-audit.js` (profil), `x-post-growth.js` (post), `x-engage-likes.js` (like max 3, jeda 20–30 dtk).
- Bio yang disetujui Madi (9 Nov 17:39): `Airdrop hunter 🇮🇩 | Garapan gratis doang: airdrop, whitelist, testnet | Tanpa modal, tanpa nipu | IPX Fan SZN 🎧` + pin post relaunch https://x.com/akunata82/status/2119740774502035895 — **DIGANTI LAGI oleh Madi lewat chat WhatsApp ~17:56: bio sekarang `Airdrop Hunter 🇮🇩 | Early alpha, testnets & whitelists`. Foto profil diganti ke foto Maya di pantai (x-pfp-maya-beach-crop.jpg) oleh agen chat sebelah; percobaan #1 salah input dan malah mengganti BANNER jadi foto Maya.**
- Komen di CT besar (disetujui Madi 9 Nov 18:04): reply ke akun besar crypto/airdrop supaya orang kenal — hanya kalau ada yang benar-benar bisa ditambahin (insight/pertanyaan/tips), max ~5 reply/hari, tanpa shill/link referral di reply.
