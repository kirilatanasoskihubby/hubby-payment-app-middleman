# Testing Guide

## Quick Test with Script

Run the comprehensive test script:

```bash
./run-tests.sh
```

This will test:
1. ✅ Normal payload (should work)
2. ✅ Large payload ~500KB (should work)
3. ✅ Near-limit payload ~1.04MB (should work - just under 1MB)
4. ❌ Over-limit payload ~1.1MB (should be rejected with 413)
5. 🔄 Rate limiting (5 rapid requests)

---

## Testing via Postman / ngrok

Your ngrok URL: `https://0711fb5d64e7.ngrok-free.app/forward`

### Test 1: Normal Request ✅

```json
{
  "userId": "12345",
  "amount": 99.99,
  "currency": "USD",
  "description": "Payment for premium plan"
}
```

**Expected**: Success (or backend error if backend has issues)

---

### Test 2: Large Request ~100KB ✅

Use this Node.js snippet to generate payload:

```javascript
const payload = {
  userId: "12345",
  amount: 99.99,
  largeData: 'A'.repeat(100000) // 100KB
};
console.log(JSON.stringify(payload));
```

**Expected**: Should work (payload is under 1MB)

---

### Test 3: Very Large Request ~1.1MB ❌

```javascript
const payload = {
  userId: "12345",
  amount: 99.99,
  veryLargeData: 'B'.repeat(1100000) // 1.1MB
};
console.log(JSON.stringify(payload));
```

**Expected Response**:
```json
{
  "error": "Payload too large",
  "message": "Request body exceeds the 1MB limit"
}
```

---

### Test 4: Rate Limiting 🔄

Make 101 requests within 1 minute.

**First 100 requests**: Should work  
**101st request**: Should get rate limited

**Expected Response** (after 100 requests):
```json
{
  "error": "Too many requests, please try again later."
}
```

**Check Rate Limit Headers** in response:
- `RateLimit-Limit: 100`
- `RateLimit-Remaining: 99, 98, 97...`
- `RateLimit-Reset: [timestamp]`

---

## Quick Rate Limit Test

To quickly test rate limiting without making 101 requests, temporarily change your `.env`:

```bash
# Temporarily set to 5 requests per minute for testing
RATE_LIMIT=5
```

Then make 6 requests in Postman. The 6th will be rate limited.

Don't forget to change it back to 100 for production!

---

## Checking Response Headers

In Postman, check the **Headers** tab in the response to see:

```
RateLimit-Limit: 100
RateLimit-Remaining: 95
RateLimit-Reset: 1699886400
```

This tells you:
- **Limit**: 100 requests allowed per window
- **Remaining**: How many requests you have left
- **Reset**: When the limit resets (Unix timestamp)

