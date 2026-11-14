#!/bin/bash
# Bug Bounty Recon Script
# Usage: bash recon.sh <target-domain>

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Usage: bash recon.sh <target-domain>"
    exit 1
fi

echo "=== RECON: $TARGET ==="
echo ""

echo "[1] DNS Records"
dig +short $TARGET
dig +short ANY $TARGET
echo ""

echo "[2] Subdomains"
for sub in api admin dev staging app mail ftp cdn static assets img images media upload files test beta portal dashboard backend frontend www2; do
    result=$(dig +short "$sub.$TARGET" 2>/dev/null)
    if [ -n "$result" ]; then
        echo "  $sub.$TARGET -> $result"
    fi
done
echo ""

echo "[3] SSL Certificate"
echo | openssl s_client -connect $TARGET:443 -servername $TARGET 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null
echo ""

echo "[4] HTTP Headers"
curl -sI "https://$TARGET" -H "User-Agent: Mozilla/5.0" 2>/dev/null | head -20
echo ""

echo "[5] Common Paths"
for path in robots.txt sitemap.xml .well-known/security.txt .env .git/HEAD admin login api graphql swagger; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "https://$TARGET/$path" -H "User-Agent: Mozilla/5.0" --max-time 5 2>/dev/null)
    if [ "$code" != "000" ] && [ "$code" != "403" ] && [ "$code" != "503" ]; then
        echo "  /$path -> $code"
    fi
done
echo ""

echo "[6] Wayback Machine"
curl -s "https://web.archive.org/cdx/search/cdx?url=$TARGET/*&output=text&fl=original&limit=20" 2>/dev/null | head -20
echo ""

echo "[7] IP Info"
ip=$(dig +short $TARGET | head -1)
if [ -n "$ip" ]; then
    curl -s "https://ipinfo.io/$ip" 2>/dev/null | head -10
fi
echo ""

echo "=== RECON COMPLETE ==="
