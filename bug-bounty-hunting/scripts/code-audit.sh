#!/bin/bash
# Source Code Audit Script
# Usage: bash code-audit.sh <repo-dir> [src-subdir]

REPO_DIR=$1
SRC_DIR=${2:-src}

if [ -z "$REPO_DIR" ]; then
    echo "Usage: bash code-audit.sh <repo-dir> [src-subdir]"
    exit 1
fi

cd "$REPO_DIR/$SRC_DIR" 2>/dev/null || cd "$REPO_DIR"

echo "=== CODE AUDIT: $(pwd) ==="
echo ""

echo "[1] RCE VECTORS (eval, exec, system, etc)"
grep -rn 'eval\s*(\|exec\s*(\|system\s*(\|passthru\s*(\|shell_exec\s*(\|proc_open\s*(\|popen\s*(' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | head -20
echo ""

echo "[2] DESERIALIZATION (unserialize)"
grep -rn 'unserialize\s*(' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | head -20
echo ""

echo "[3] SQL INJECTION (raw queries)"
grep -rn 'executeQuery\|executeStatement\|->query(' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | grep -i 'select\|insert\|update\|delete\|where' | head -20
echo ""

echo "[4] FILE UPLOAD"
grep -rn 'move_uploaded_file\|tmp_name\|\$_FILES\|UploadedFile\|getClientOriginalName\|getClientMimeType' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | head -20
echo ""

echo "[5] SSRF (HTTP requests)"
grep -rn 'curl_setopt\|CURLOPT_URL\|file_get_contents\s*(\|HttpClient\|GuzzleHttp\|->request(' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | head -20
echo ""

echo "[6] SSRF VALIDATION (check if exists)"
grep -rn 'FILTER_VALIDATE_IP\|FILTER_FLAG_NO_PRIV_RANGE\|isPrivate\|isReserved' --include='*.php' . 2>/dev/null | head -10
echo ""

echo "[7] AUTH BYPASS (unauthenticated endpoints)"
grep -rn 'auth_required.*false\|auth_required.*0' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | head -20
echo ""

echo "[8] PATH TRAVERSAL (file operations)"
grep -rn 'file_get_contents\|file_put_contents\|readfile\|include\s*(\|require\s*(' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock\|vendor' | head -20
echo ""

echo "[9] XSS (template injection)"
grep -rn '|raw\|autoescape.*false' --include='*.twig' . 2>/dev/null | head -10
echo ""

echo "[10] MASS ASSIGNMENT (unprotected fields)"
grep -rn 'fillable\|guard\|ApiAware\|WriteProtected' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock' | head -15
echo ""

echo "[11] DIRECT UNWRAPPED unserialize (bypasses safe wrappers)"
grep -rn '\bunserialize\s*(' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|spec\|mock\|safe_unserialize\|allowed_classes' | head -15
echo ""

echo "[12] SSRF BLOCKLIST ANALYSIS"
echo "--- Blocklist config ---"
grep -rn 'blocklist\|block_list\|disallowed.*host\|allowed.*host' --include='*.php' --include='*.ini' --include='*.yml' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor' | head -10
echo "--- Private IP validation (missing = SSRF risk) ---"
grep -rn 'FILTER_FLAG_NO_PRIV_RANGE\|FILTER_FLAG_NO_RES_RANGE\|isPrivate\|isReserved\|169\.254\|127\.0\.0\|10\.\|172\.1[6-9]\|172\.2[0-9]\|172\.3[01]\|192\.168' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor' | head -10
echo ""

echo "[13] TWIG |raw WITH USER INPUT TRACE"
echo "--- All |raw usage ---"
grep -rn '|raw' --include='*.twig' . 2>/dev/null | head -15
echo "--- High-risk: error/message/user vars with |raw ---"
grep -rn '|raw' --include='*.twig' . 2>/dev/null | grep -i 'error\|message\|user\|login\|name\|email\|input\|request\|label\|desc' | head -10
echo ""

echo "[14] AUTH BYPASS PATTERNS"
grep -rn 'logme\|autoLogin\|auto_login\|skipAuth\|disableAuth\|noAuth' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor' | head -10
echo ""

echo "[15] OPEN REDIRECT (redirect URL validation)"
grep -rn 'redirect\|redirectTo\|Location:' --include='*.php' . 2>/dev/null | grep -i 'request\|param\|get\|post\|input\|user' | head -10
echo ""

echo "[16] EXCEPTION INFO DISCLOSURE (getFile/getLine in __toString)"
grep -rn '__toString' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor' | grep -i 'getFile\|getLine\|getTrace' | head -10
echo ""

echo "[17] rawSafeDecoded / is_safe FILTERS (potential XSS if used in non-HTML context)"
grep -rn 'rawSafeDecoded\|is_safe.*all' --include='*.php' --include='*.twig' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor' | head -10
echo ""

echo "[18] WEAK PASSWORD HASHING (md5, sha1)"
grep -rn 'md5\s*(.*password\|sha1\s*(.*password\|md5\s*(.*\$pass\|sha1\s*(.*\$pass' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor\|//\|/\*' | head -10
echo ""

echo "[19] HTTP CLIENT MULTI-TRIGGER (find all SSRF entry points)"
grep -rn 'sendHttpRequest\|sendHttpRequestBy\|HttpClient\|GuzzleHttp\|curl_exec\|file_get_contents.*http' --include='*.php' . 2>/dev/null | grep -v 'test\|Test\|node_modules\|vendor\|core/Http.php\|libs/' | head -20
echo ""

echo "=== AUDIT COMPLETE ==="
