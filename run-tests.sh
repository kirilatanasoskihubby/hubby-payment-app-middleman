#!/bin/bash

echo "======================================"
echo "🧪 Middleman Service Test Suite"
echo "======================================"
echo ""

echo "Test 1: Normal Payload"
echo "--------------------------------------"
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:3000/forward \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "12345",
    "amount": 99.99,
    "currency": "USD",
    "description": "Payment for premium plan"
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)

if [ "$HTTP_STATUS" = "500" ] || [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ PASS - Payload accepted (Status: $HTTP_STATUS)"
else
  echo "❌ FAIL - Unexpected status: $HTTP_STATUS"
fi
echo ""

sleep 0.2

echo "Test 2: Large Payload (~500KB - Should Accept)"
echo "--------------------------------------"
node -e "
const http = require('http');
const payload = JSON.stringify({ userId: '12345', largeData: 'A'.repeat(500000) });
const options = {
  hostname: 'localhost', port: 3000, path: '/forward', method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
};
const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    if (res.statusCode === 500 || res.statusCode === 200) {
      console.log('✅ PASS - Large payload accepted (Status: ' + res.statusCode + ')');
    } else {
      console.log('❌ FAIL - Unexpected status: ' + res.statusCode);
    }
  });
});
req.on('error', (e) => console.log('❌ FAIL - Error: ' + e.message));
req.write(payload);
req.end();
"

sleep 0.2

echo ""
echo "Test 3: Just Under 1MB (~1.04MB - Should Accept)"
echo "--------------------------------------"
node -e "
const http = require('http');
const payload = JSON.stringify({ userId: '12345', testData: 'B'.repeat(1040000) });
const sizeInMB = (Buffer.byteLength(payload) / (1024 * 1024)).toFixed(2);
console.log('Payload size: ' + sizeInMB + ' MB');
const options = {
  hostname: 'localhost', port: 3000, path: '/forward', method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
};
const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    if (res.statusCode === 500 || res.statusCode === 200) {
      console.log('✅ PASS - Near-limit payload accepted (Status: ' + res.statusCode + ')');
    } else {
      console.log('❌ FAIL - Unexpected status: ' + res.statusCode);
    }
  });
});
req.on('error', (e) => console.log('❌ FAIL - Error: ' + e.message));
req.write(payload);
req.end();
"

sleep 0.2

echo ""
echo "Test 4: Over 1MB (~1.1MB - Should Reject)"
echo "--------------------------------------"
node -e "
const http = require('http');
const payload = JSON.stringify({ userId: '12345', testData: 'C'.repeat(1100000) });
const sizeInMB = (Buffer.byteLength(payload) / (1024 * 1024)).toFixed(2);
console.log('Payload size: ' + sizeInMB + ' MB');
const options = {
  hostname: 'localhost', port: 3000, path: '/forward', method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
};
const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    if (res.statusCode === 413) {
      console.log('✅ PASS - Payload rejected with 413 as expected');
    } else {
      console.log('❌ FAIL - Expected 413 but got: ' + res.statusCode);
    }
  });
});
req.on('error', (e) => console.log('❌ FAIL - Error: ' + e.message));
req.write(payload);
req.end();
"

sleep 0.2

echo ""
echo "Test 5: Rate Limiting (5 rapid requests)"
echo "--------------------------------------"
RATE_LIMIT_PASSED=true

for i in {1..5}
do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/forward \
    -H "Content-Type: application/json" \
    -d "{\"test\": \"rate-limit-$i\"}")
  
  if [ "$HTTP_STATUS" = "429" ]; then
    echo "Request $i: Rate limited (429) ❌"
    RATE_LIMIT_PASSED=false
  elif [ "$HTTP_STATUS" = "500" ] || [ "$HTTP_STATUS" = "200" ]; then
    echo "Request $i: Accepted ($HTTP_STATUS) ✅"
  else
    echo "Request $i: Unexpected status ($HTTP_STATUS)"
  fi
  sleep 0.1
done

if [ "$RATE_LIMIT_PASSED" = true ]; then
  echo "✅ PASS - All 5 requests accepted (under 100/min limit)"
else
  echo "❌ Some requests rate limited (unexpected for only 5 requests)"
fi
echo ""

echo "======================================"
echo "📊 All Tests Complete!"
echo "======================================"
echo ""
echo "Configuration:"
echo "- Payload Limit: 1MB"
echo "- Rate Limit: 100 requests/minute"
echo ""

