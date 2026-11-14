# PoC Creation Guide for Bug Bounty

## General Approach

A good PoC demonstrates the vulnerability without requiring a full production setup.

### Standalone PoC (Preferred)
Extract the vulnerable code path into a standalone script that:
1. Simulates the vulnerable component
2. Shows the attack in action
3. Can be run without the full application

### Why Standalone Works
- Reviewers can verify quickly
- No need to set up full application
- Clear demonstration of the specific vulnerability
- Easier to reproduce

## SSRF PoC Template

### Structure
```
ssrf-poc/
├── README.md              ← Report with vulnerability details
├── test_ssrf.php          ← Standalone test script
├── listener.php           ← HTTP server to capture requests
├── malicious-app/         ← Attack payload (if applicable)
│   └── manifest.xml
└── vendor/                ← Dependencies (if needed)
```

### listener.php
```php
<?php
// Capture and display incoming requests
$logEntry = [
    'timestamp' => date('Y-m-d H:i:s'),
    'method'    => $_SERVER['REQUEST_METHOD'] ?? 'UNKNOWN',
    'uri'       => $_SERVER['REQUEST_URI'] ?? '/',
    'headers'   => [],
    'body'      => file_get_contents('php://input'),
    'source_ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
];

// Display captured request
echo "=== REQUEST CAPTURED ===\n";
echo "Method: {$logEntry['method']}\n";
echo "URI: {$logEntry['uri']}\n";
echo "Source: {$logEntry['source_ip']}\n";

// Log to file
file_put_contents(__DIR__ . '/requests.log', json_encode($logEntry) . "\n", FILE_APPEND);
```

### test_ssrf.php Pattern
```php
<?php
require_once __DIR__ . '/vendor/autoload.php';

// 1. Show vulnerable code path
echo "[1] VULNERABLE CODE:\n";
// ... paste vulnerable code ...

// 2. Show protected code (comparison)
echo "[2] PROTECTED CODE (what it should be):\n";
// ... paste protected code ...

// 3. Demonstrate the attack
$client = new GuzzleHttp\Client(['timeout' => 5]);
$request = new GuzzleHttp\Psr7\Request('POST', 'http://127.0.0.1:9999/internal');
$response = $client->send($request);
echo "Status: {$response->getStatusCode()}\n";
echo "Body: {$response->getBody()->getContents()}\n";

// 4. Show comparison table
echo "[3] COMPARISON:\n";
// Table showing what's blocked vs allowed in each component
```

### Running the PoC
```bash
# Terminal 1: Start listener
php -S 0.0.0.0:9999 listener.php

# Terminal 2: Run test
php test_ssrf.php
```

## XSS PoC Template
```php
<?php
// Store XSS PoC
$payload = '<script>alert(document.cookie)</script>';
echo "Payload: {$payload}\n";
echo "Submit this to the vulnerable field\n";
echo "Then visit the page where it's rendered without escaping\n";
```

## IDOR PoC Template
```bash
# Step 1: Access your own resource
curl -H "Authorization: Bearer YOUR_TOKEN" https://target.com/api/user/123

# Step 2: Access another user's resource (change ID)
curl -H "Authorization: Bearer YOUR_TOKEN" https://target.com/api/user/124

# Step 3: If both return 200 with data = IDOR vulnerability
```

## Report Template (for submission)

```markdown
## Summary
[One paragraph describing the vulnerability]

## Vulnerability Details
- **Type**: SSRF / XSS / IDOR / etc.
- **Severity**: P2 (High) — justify your assessment
- **Affected Component**: [file path and function]

## Root Cause
[Explain WHY the vulnerability exists]
[Show the vulnerable code with line numbers]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Proof of Concept
[Attach or include the PoC code]
[Include screenshots of successful exploitation]

## Impact
[What can an attacker achieve?]
[Be specific: "Access AWS credentials via metadata service"]

## Remediation
[Show how to fix it — optional but impressive]
```

## Tips
- Keep PoC minimal — show only what's needed
- Use localhost/127.0.0.1 for SSRF targets (safe and clear)
- Include both vulnerable and fixed code in comments
- Screenshot everything — reviewers want visual proof
- Test your PoC before submitting — make sure it actually works
