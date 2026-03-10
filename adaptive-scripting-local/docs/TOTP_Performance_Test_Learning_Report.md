# TOTP MFA Performance Test - Learning Report

## WSO2 Identity Server 7.2.x | Adaptive Scripting | JMeter Load Testing

---

## Table of Contents

1. [Objective](#1-objective)
2. [Architecture Overview](#2-architecture-overview)
3. [Problem #1: TOTP Enrollment Not Persisting](#3-problem-1-totp-enrollment-not-persisting)
4. [Problem #2: Basic Auth Blocked for TOTP Self-Service API](#4-problem-2-basic-auth-blocked-for-totp-self-service-api)
5. [Problem #3: Bearer Token Invalidated After TOTP INIT](#5-problem-3-bearer-token-invalidated-after-totp-init)
6. [Problem #4: TOTP Replay Protection Causing 40% Error Rate](#6-problem-4-totp-replay-protection-causing-40-error-rate)
7. [Problem #5: Assertions Masking Real Failures](#7-problem-5-assertions-masking-real-failures)
8. [Problem #6: Bash Special Character Escaping](#8-problem-6-bash-special-character-escaping)
9. [The Correct TOTP Enrollment Flow (IS 7.2.x)](#9-the-correct-totp-enrollment-flow-is-72x)
10. [The Correct JMeter Authentication Flow](#10-the-correct-jmeter-authentication-flow)
11. [TOTP Fundamentals and Why Replay Protection Exists](#11-totp-fundamentals-and-why-replay-protection-exists)
12. [Debugging Methodology](#12-debugging-methodology)
13. [Key Takeaways](#13-key-takeaways)

---

## 1. Objective

Build a JMeter performance test that exercises the **OIDC Authorization Code flow with TOTP MFA** on WSO2 Identity Server 7.2.x, where:

- An **adaptive authentication script** enforces two-step authentication:
  - Step 1: Username/Password (BasicAuthenticator)
  - Step 2: TOTP code (totp authenticator)
- Multiple concurrent JMeter threads each use a **unique test user** with a unique TOTP secret
- The test must run with **0% error rate**

### Why This Is Non-Trivial

TOTP MFA introduces several complexities not present in password-only auth tests:

1. Each user must be **enrolled in TOTP** before the test (enrollment creates a shared secret)
2. TOTP codes are **time-based** (change every 30 seconds)
3. TOTP has **replay protection** (same code can't be used twice in the same window)
4. The enrollment API has specific requirements that differ from the authentication API
5. The IS server blocks certain authentication methods for certain APIs

---

## 2. Architecture Overview

### Authentication Flow (What JMeter Simulates)

```
Browser/JMeter                         WSO2 Identity Server 7.2.x
      |                                         |
      |  1. GET /oauth2/authorize               |
      |  (client_id, redirect_uri, scope)       |
      |---------------------------------------->|
      |  302 -> /login.do?sessionDataKey=A      |
      |<----------------------------------------|
      |                                         |
      |  2. POST /commonauth                    |   Adaptive Script
      |  (sessionDataKey=A, username, password)  |   Step 1: BasicAuth
      |---------------------------------------->|   -> onSuccess: executeStep(2)
      |  302 -> /totp.do?sessionDataKey=B       |
      |<----------------------------------------|
      |                                         |
      |  2c. POST /commonauth                   |   Adaptive Script
      |  (sessionDataKey=B, token=TOTP_CODE)    |   Step 2: TOTP
      |---------------------------------------->|
      |  302 -> /oauth2/authorize?              |
      |         sessionDataKey=C                |
      |<----------------------------------------|
      |                                         |
      |  2b. GET /t/carbon.super/               |
      |      oauth2/authorize?sessionDataKey=C  |
      |---------------------------------------->|
      |  302 -> callback?code=AUTH_CODE         |
      |<----------------------------------------|
      |                                         |
      |  3. POST /oauth2/token                  |
      |  (grant_type=authorization_code,        |
      |   code=AUTH_CODE)                       |
      |---------------------------------------->|
      |  200 {access_token, id_token}           |
      |<----------------------------------------|
```

### Key Concepts

- **sessionDataKey**: A unique identifier that ties each step of the authentication flow together. IS generates a new one at each step.
- **Adaptive Script**: JavaScript (GraalJS) code that runs inside IS and decides the authentication flow. In our case: password first, then TOTP.
- **TOTP Secret**: A Base32-encoded shared secret used to generate time-based 6-digit codes. Both IS and the client must know this secret.
- **Authorization Code**: The final output of the authentication flow, exchanged for tokens.

---

## 3. Problem #1: TOTP Enrollment Not Persisting

### Symptom

After running the setup script to enroll test users in TOTP, subsequent login attempts would redirect to `totp_enroll.do` (enrollment page) instead of `totp.do` (code entry page). This meant the enrollment was not being saved by IS.

### Root Cause

The TOTP self-service VALIDATE API field name was wrong.

```
WRONG:   {"action": "VALIDATE", "verifyCode": "123456"}     -> 400 Bad Request
CORRECT: {"action": "VALIDATE", "verificationCode": "123456"} -> {"isValid": true}
```

### Why This Was Hard to Find

1. The API returned **400 "Provided request body content is not in the expected format"** for the wrong field name, not a clear "unknown field" error
2. The field name `verifyCode` seemed plausible and was used in older documentation
3. No official Swagger/OpenAPI spec was readily available for this endpoint
4. The error didn't indicate which field was wrong

### How We Found It

Systematic trial of different field names against the API:

```bash
# Wrong - returns 400
curl -X POST /api/users/v1/me/totp -d '{"action":"VALIDATE","verifyCode":"123456"}'

# Correct - returns {"isValid": true/false}
curl -X POST /api/users/v1/me/totp -d '{"action":"VALIDATE","verificationCode":"123456"}'
```

### Lesson

When an API returns a format error, always question field names. Test with minimal payloads and add fields one at a time. Check the actual IS source code or use tools like the IS Console UI's network tab to see what field names the official UI uses.

---

## 4. Problem #2: Basic Auth Blocked for TOTP Self-Service API

### Symptom

```
POST /api/users/v1/me/totp
Authorization: Basic base64(username:password)

Response: "This method is blocked for the requests with basic authentication."
```

### Root Cause

WSO2 IS 7.2.x **blocks Basic authentication** for the TOTP self-service API (`/api/users/v1/me/totp`). This is a security design decision — the `/me` APIs are intended for authenticated user sessions (Bearer tokens), not for direct credential submission.

### Why Basic Auth Is Blocked

The `/me` endpoint represents the currently authenticated user's profile. In a real-world scenario:

1. The user has already authenticated (e.g., via OAuth2 login)
2. They have a Bearer token from that authentication
3. They use the Bearer token to access self-service APIs

Allowing Basic Auth would bypass the normal authentication flow and could be a security risk (passwords transmitted in every request vs. short-lived tokens).

### Solution

Use OAuth2 **password grant** to obtain a Bearer token first, then use the Bearer token for TOTP enrollment:

```bash
# Step 1: Get Bearer token via password grant
TOKEN=$(curl -X POST /oauth2/token \
  --data-urlencode "grant_type=password" \
  --data-urlencode "username=test_user" \
  --data-urlencode "password=Test@1234!" \
  --data-urlencode "client_id=CLIENT_ID" \
  --data-urlencode "client_secret=CLIENT_SECRET" \
  --data-urlencode "scope=internal_login")

# Step 2: Use Bearer token for TOTP APIs
curl -X POST /api/users/v1/me/totp \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"action":"INIT"}'
```

### Lesson

Different API endpoints in IS have different authentication requirements. Self-service (`/me`) APIs require Bearer tokens, not Basic Auth. Admin APIs (`/scim2/Users`, `/api/server/v1/applications`) accept Basic Auth with admin credentials.

---

## 5. Problem #3: Bearer Token Invalidated After TOTP INIT

### Symptom

When attempting to:
1. Create user
2. INIT TOTP enrollment (sets `totpEnabled=true`)
3. Get Bearer token via password grant
4. VALIDATE enrollment

Step 3 would fail because password grant was rejected for TOTP-enabled users.

### Root Cause

The INIT API call sets `totpEnabled=true` on the user's profile. Once this flag is set, IS requires TOTP completion for all authentication flows, **including password grant**. Since we're trying to enroll (not yet validate), the user can't complete TOTP, creating a deadlock.

### Timeline of What Happens

```
1. Create user              -> totpEnabled=false, password grant works
2. INIT TOTP                -> totpEnabled=true, IS now expects TOTP for all auth
3. Password grant attempt   -> FAILS: "Authentication failed" (TOTP required but not provided)
4. Can't get Bearer token   -> Can't call VALIDATE -> Enrollment stuck
```

### Solution

**Get the Bearer token BEFORE calling INIT:**

```
1. Create user              -> totpEnabled=false
2. Get Bearer token         -> SUCCESS (no TOTP required yet)
3. INIT TOTP (using token)  -> totpEnabled=true, returns QR code with secret
4. VALIDATE (using SAME token) -> Enrollment complete
```

The Bearer token obtained in step 2 remains valid even after INIT sets `totpEnabled=true`, because token validity is determined at issuance time, not on each use.

### Lesson

In multi-step setup flows, carefully consider the **order of operations** and how each step changes the system state. A state change in one step can invalidate assumptions needed by subsequent steps.

---

## 6. Problem #4: TOTP Replay Protection Causing 40% Error Rate

### Symptom

The JMeter test consistently showed **~40% error rate**:
- Steps 1, 2, 2c: ~0% error (appeared to succeed)
- Steps 2b, 3: ~100% error

The first iteration of the test always succeeded. All subsequent iterations failed.

### Root Cause: TOTP Replay Protection

**How TOTP Works:**

```
TOTP Code = HMAC-SHA1(secret, floor(current_time / 30))
```

The TOTP algorithm uses the current Unix timestamp divided by 30 (the time step). This means:
- Within any 30-second window, the same secret always produces the **same 6-digit code**
- WSO2 IS tracks used TOTP codes and **rejects a code that has already been used** in the current window

**What Happened in JMeter:**

```
Time: 00:00.100 - Iteration 1: TOTP code = 482917 -> ACCEPTED (first use)
Time: 00:00.300 - Iteration 2: TOTP code = 482917 -> REJECTED (same code, same window)
Time: 00:00.500 - Iteration 3: TOTP code = 482917 -> REJECTED (same code, same window)
...
Time: 00:30.000 - Next window:  TOTP code = 739201 -> ACCEPTED (new code)
Time: 00:30.200 - Next iter:    TOTP code = 739201 -> REJECTED (same code again)
```

Each complete iteration took <1 second (Steps 1-3 total ~50ms), so multiple iterations happened within the same 30-second TOTP window.

### Why It Appeared as 40% Error Rate

The test has 5 steps per iteration. When TOTP is rejected:
- Steps 1, 2, 2c: All return HTTP 302 and pass their assertions
- Step 2b: Returns HTTP 302 but to `oauth2_error.do` (no auth code) -> FAILS
- Step 3: Uses invalid auth code -> FAILS

2 failures out of 5 steps = **40%** error rate.

### The Hidden Failure Chain

```
Step 2c (TOTP rejected):
  IS redirects to: /totp.do?authFailure=true&sessionDataKey=B
  Assertion checks: HTTP/1.1 302 -> PASSES (it IS a 302!)
  Regex extracts: sessionDataKey=B (from the ERROR redirect!)

Step 2b (uses invalid session key):
  GET /oauth2/authorize?sessionDataKey=B
  IS redirects to: /oauth2_error.do?oauthErrorCode=invalid_request
  Assertion checks: HTTP/1.1 302 -> PASSES
  Regex extracts: code=... -> NOT FOUND (no code in error redirect)
  JSR223 assertion: FAILS (authCode == AUTH_CODE_NOT_FOUND)
```

### Solution: TOTP Replay Guard

Added logic in the TOTP code calculator to track the last-used time step and sleep until the next 30-second window:

```groovy
long currentTimeStep = System.currentTimeMillis() / 1000L / 30L

String lastStepStr = vars.get("lastTotpTimeStep")
if (lastStepStr != null) {
    long lastStep = Long.parseLong(lastStepStr)
    if (currentTimeStep == lastStep) {
        // Same 30-second window - sleep until next one
        long nextWindowMs = (currentTimeStep + 1) * 30L * 1000L
        long sleepMs = nextWindowMs - System.currentTimeMillis() + 100
        Thread.sleep(sleepMs)
        currentTimeStep = System.currentTimeMillis() / 1000L / 30L
    }
}
vars.put("lastTotpTimeStep", String.valueOf(currentTimeStep))
```

### Throughput Implications

This means each user can only authenticate **once per 30-second window**:
- 5 users = max ~0.17 TPS (5 auths per 30 seconds)
- 50 users = max ~1.67 TPS
- 150 users = max ~5 TPS

This is an **inherent limitation of TOTP** as a second factor. To increase throughput, create more users.

### Lesson

TOTP replay protection is a server-side security feature that limits how often the same user can authenticate. Performance tests must account for this fundamental constraint. The same issue would affect any system using TOTP (Google Authenticator, Microsoft Authenticator, etc.).

---

## 7. Problem #5: Assertions Masking Real Failures

### Symptom

The JMeter test showed Steps 1, 2, and 2c as "successful" even though 2c was actually failing (TOTP rejected). Only Steps 2b and 3 showed as failures, making it seem like the post-auth step was the problem.

### Root Cause

The assertions on Steps 2 and 2c only checked for **HTTP 302** status code:

```xml
<ResponseAssertion>
  <collectionProp name="Asserion.test_strings">
    <stringProp>HTTP/1.1 302</stringProp>
  </collectionProp>
</ResponseAssertion>
```

But WSO2 IS returns **302 for both success AND failure cases**:

| Scenario | HTTP Status | Location Header |
|----------|------------|-----------------|
| Password accepted, redirect to TOTP | 302 | `/totp.do?sessionDataKey=X` |
| Password failed, redirect to login | 302 | `/login.do?authFailure=true&sessionDataKey=Y` |
| TOTP accepted, redirect to authorize | 302 | `/oauth2/authorize?sessionDataKey=Z` |
| TOTP rejected, redirect to TOTP retry | 302 | `/totp.do?authFailure=true&sessionDataKey=W` |

All four cases return 302! The assertion `HTTP/1.1 302` passes for all of them.

### Why This Is a Common Web Auth Pattern

Web applications use HTTP 302 redirects for flow control, not just for success. In the authentication framework:
- Success: Redirect to the next step
- Failure: Redirect back to the current step with `authFailure=true`

Both are valid HTTP responses from the server's perspective.

### Solution

Added a JSR223 assertion that checks the **content** of the redirect, not just the status code:

```groovy
def headers = prev.getResponseHeaders()
if (headers != null && headers.contains("authFailure=true")) {
    AssertionResult.setFailure(true)
    AssertionResult.setFailureMessage(
        "TOTP code was rejected (authFailure=true in redirect)."
    )
    return
}
```

### Lesson

**Never assert only on HTTP status codes for auth flows.** Always verify the redirect destination or response content. A 302 redirect to an error page is still a "failure" even though the HTTP status is the same as a success redirect. This is one of the most common mistakes in JMeter auth flow testing.

### General Rule for Auth Flow Assertions

```
Step N assertion should verify:
  1. HTTP status code (302 for redirects, 200 for final response)
  2. Redirect destination contains expected path (e.g., "totp.do" not "login.do")
  3. No error indicators in the redirect (e.g., "authFailure=true" absent)
  4. Expected correlation variable was extracted successfully
```

---

## 8. Problem #6: Bash Special Character Escaping

### Symptom

The setup script failed to create users via SCIM2 API with `400 invalidSyntax` errors.

### Root Cause

The test password `Test@1234!` contains `!`, which has special meaning in Bash:

```bash
# WRONG - Bash history expansion
PASSWORD="Test@1234!"
echo "$PASSWORD"  # Bash tries to expand !234 or !" as history reference

# WRONG - Inline JSON with special characters
curl -d "{\"password\":\"${PASSWORD}\"}"  # ! causes expansion inside double quotes
```

### Why `!` Is Special in Bash

In Bash, `!` triggers **history expansion** when inside double quotes:
- `!event` - refers to a previous command
- `!"` at end of a quoted string can cause unexpected behavior
- Only single quotes fully prevent this: `'Test@1234!'`

But single quotes prevent variable expansion, so you can't use `'${VAR}'` inside them.

### Solution

Use Python to generate JSON files, avoiding Bash string interpolation entirely:

```bash
python3 -c "
import json
print(json.dumps({
    'schemas': ['urn:ietf:params:scim:schemas:core:2.0:User'],
    'userName': '${USERNAME}',
    'password': '${TEST_PASSWORD}',
    'name': {'givenName': 'TOTP', 'familyName': 'User${i}'},
    'emails': [{'primary': True, 'value': '${USERNAME}@example.com'}]
}))
" > /tmp/totp_create_user.json

curl -d @/tmp/totp_create_user.json ...
```

Or use heredoc with single-quoted delimiter:

```bash
python3 << 'PYEOF' > /tmp/create_user.json
# Inside this heredoc, $VAR and ! are NOT expanded by Bash
import json
print(json.dumps({...}))
PYEOF
```

### macOS-Specific Issue

`head -n -1` (remove last line) doesn't work on macOS:
```bash
head -n -1 file.txt  # Linux: works, macOS: "illegal line count -- -1"
```

macOS uses BSD utilities, not GNU. Use Python or `sed` instead.

### Lesson

When building shell scripts that handle passwords or special characters:
1. Avoid inline JSON construction with Bash variables
2. Use a proper JSON library (Python's `json.dumps` handles escaping correctly)
3. Write to temp files and use `curl -d @file.json` pattern
4. Test scripts with passwords containing `!`, `$`, `"`, `'`, `\`, `&`

---

## 9. The Correct TOTP Enrollment Flow (IS 7.2.x)

This is the definitive enrollment flow for WSO2 IS 7.2.x:

```
Step 1: Create User (SCIM2)
  POST /scim2/Users
  Auth: Basic (admin:admin)
  Body: {schemas, userName, password, name, emails}
  Result: User created with totpEnabled=false

Step 2: Get Bearer Token (BEFORE INIT!)
  POST /oauth2/token
  Body: grant_type=password, username, password, client_id, client_secret, scope=internal_login
  Result: Bearer token for the user
  CRITICAL: Must happen before INIT, because INIT sets totpEnabled=true

Step 3: INIT TOTP Enrollment
  POST /api/users/v1/me/totp
  Auth: Bearer <token from step 2>
  Body: {"action": "INIT"}
  Result: {"qrCodeUrl": "base64_encoded_otpauth_uri"}
  Side effect: Sets totpEnabled=true on user profile

  Extract secret:
    otpauth://totp/carbon.super:username?secret=ABCDEF123&issuer=carbon.super
    Base64 decode qrCodeUrl -> parse URI -> extract 'secret' query parameter

Step 4: VALIDATE TOTP Enrollment
  POST /api/users/v1/me/totp
  Auth: Bearer <same token from step 2>
  Body: {"action": "VALIDATE", "verificationCode": "482917"}
  Result: {"isValid": true}
  Side effect: Persists the TOTP secret permanently

Verification:
  GET /api/users/v1/me/totp
  Auth: Bearer <token>
  If enrolled: Returns consistent QR code (same secret each time)
  If NOT enrolled: Returns different QR code each time (random generation)
```

### API Summary Table

| Action | Endpoint | Auth | Body | Response |
|--------|----------|------|------|----------|
| Create user | POST /scim2/Users | Basic (admin) | SCIM2 JSON | User object |
| Get token | POST /oauth2/token | None (client creds in body) | form-urlencoded | {access_token} |
| Init TOTP | POST /api/users/v1/me/totp | Bearer | {"action":"INIT"} | {qrCodeUrl} |
| Validate TOTP | POST /api/users/v1/me/totp | Bearer | {"action":"VALIDATE","verificationCode":"..."} | {isValid} |
| Check enrollment | GET /api/users/v1/me/totp | Bearer | - | {qrCodeUrl} |
| Refresh secret | POST /api/users/v1/me/totp | Bearer | {"action":"REFRESH"} | {qrCodeUrl} (new) |

---

## 10. The Correct JMeter Authentication Flow

### Flow Diagram with Correlation Variables

```
Step 1: GET /oauth2/authorize
  Input:  client_id, redirect_uri, response_type=code, scope=openid
  Output: sessionDataKey (from Location header)
  Assert: HTTP 302, sessionDataKey != NOT_FOUND
         |
         v
Step 2: POST /commonauth (Password)
  Input:  sessionDataKey, username, password
  Output: totpSessionKey (from Location header)
  Assert: HTTP 302, redirect to totp.do (NOT login.do), totpSessionKey != NOT_FOUND
         |
         v
Step 2c: POST /commonauth (TOTP Code)
  Input:  totpSessionKey, token=<calculated TOTP code>
  Output: postAuthSessionKey (from Location header)
  Assert: HTTP 302, redirect to /oauth2/authorize (NOT totp.do?authFailure),
          postAuthSessionKey != NOT_FOUND
         |
         v
Step 2b: GET /t/carbon.super/oauth2/authorize
  Input:  postAuthSessionKey
  Output: authCode (from Location header: callback?code=AUTH_CODE)
  Assert: HTTP 302, authCode != NOT_FOUND
         |
         v
Step 3: POST /oauth2/token
  Input:  grant_type=authorization_code, code=authCode, redirect_uri, client_id, client_secret
  Output: access_token, id_token
  Assert: HTTP 200, body contains "access_token", body contains "id_token"
```

### Per-Thread User Assignment

Each JMeter thread must use a unique user to avoid TOTP code collisions:

```groovy
// In JSR223 PreProcessor on Step 1
def dataLines = csvFile.readLines().drop(1)  // skip header
int threadIdx = ctx.getThreadNum() % dataLines.size()
def parts = dataLines[threadIdx].split(",")
vars.put("testUsername", parts[0])
vars.put("testPassword", parts[1])
vars.put("totpSecret",   parts[2])
```

### TOTP Code Calculation (Groovy)

```groovy
// RFC 6238 TOTP with HMAC-SHA1
byte[] key = base32Decode(secret)
long timeStep = System.currentTimeMillis() / 1000L / 30L
byte[] msg = ByteBuffer.allocate(8).putLong(timeStep).array()

Mac mac = Mac.getInstance("HmacSHA1")
mac.init(new SecretKeySpec(key, "HmacSHA1"))
byte[] hash = mac.doFinal(msg)

int offset = hash[hash.length - 1] & 0x0f
int truncated = ((hash[offset] & 0x7f) << 24)
             | ((hash[offset+1] & 0xff) << 16)
             | ((hash[offset+2] & 0xff) << 8)
             | (hash[offset+3] & 0xff)
int otp = truncated % 1000000

String totpCode = String.format("%06d", otp)
```

### TOTP Replay Guard

```groovy
long currentTimeStep = System.currentTimeMillis() / 1000L / 30L
String lastStepStr = vars.get("lastTotpTimeStep")

if (lastStepStr != null && Long.parseLong(lastStepStr) == currentTimeStep) {
    // Same 30-second window - must wait for next window
    long sleepMs = ((currentTimeStep + 1) * 30000L) - System.currentTimeMillis() + 100
    Thread.sleep(sleepMs)
    currentTimeStep = System.currentTimeMillis() / 1000L / 30L
}

vars.put("lastTotpTimeStep", String.valueOf(currentTimeStep))
```

---

## 11. TOTP Fundamentals and Why Replay Protection Exists

### How TOTP Works (RFC 6238)

TOTP (Time-based One-Time Password) generates a 6-digit code from:
1. A **shared secret** (known to both server and client)
2. The **current time** (divided into 30-second windows)

```
Time Window     Unix Time Range        TOTP Code
─────────────────────────────────────────────────
Window N        [T*30, (T+1)*30)       482917
Window N+1      [(T+1)*30, (T+2)*30)   739201
Window N+2      [(T+2)*30, (T+3)*30)   156834
```

The algorithm:
```
1. T = floor(unix_timestamp / 30)         // Current time step
2. message = T as 8-byte big-endian       // 8-byte counter
3. hash = HMAC-SHA1(secret, message)      // 20-byte hash
4. offset = last_byte_of_hash & 0x0F     // Dynamic truncation offset
5. truncated = 4 bytes at offset & 0x7FFFFFFF  // 31-bit integer
6. code = truncated % 1000000             // 6-digit code
```

### Why Replay Protection Is Necessary

Without replay protection, an attacker who intercepts a TOTP code could:
1. Observe the code `482917` being sent
2. Use the same code `482917` to authenticate as the victim
3. This must happen within the same 30-second window (or adjacent windows)

WSO2 IS prevents this by tracking used codes:
- First use of `482917` in window N: **ACCEPTED**
- Second use of `482917` in window N: **REJECTED**
- Use of `739201` in window N+1: **ACCEPTED** (new window, new code)

### Impact on Performance Testing

This creates a fundamental throughput limit:
```
Max authentications per user per 30 seconds = 1
Max TPS = number_of_users / 30
```

| Users | Max TPS | Auth/min |
|-------|---------|----------|
| 5     | 0.17    | 10       |
| 30    | 1.0     | 60       |
| 150   | 5.0     | 300      |
| 300   | 10.0    | 600      |

This is an inherent limitation of TOTP, not a server performance issue. To properly load test IS performance (vs. TOTP limits), create enough users so the TOTP window constraint isn't the bottleneck.

---

## 12. Debugging Methodology

### What Worked

1. **Adding JSR223 PostProcessors for logging**: Added debug PostProcessors that logged the actual `Location` header values. This immediately revealed the `authFailure=true` in Step 2c's redirect.

   ```groovy
   def headers = prev.getResponseHeaders()
   for (line in headers.split("\n")) {
       if (line.toLowerCase().startsWith("location:")) {
           log.info("DEBUG Location: " + line.trim())
       }
   }
   ```

2. **Starting from first principles**: Instead of trying to fix the symptoms (Step 2b failing), we traced the flow from the beginning and discovered the real failure was at Step 2c.

3. **Testing with minimal scenarios**: Running with 1 thread and 15-second duration made it easy to analyze individual iterations.

4. **Comparing iteration 1 (success) vs iteration 2 (failure)**: Since iteration 1 always succeeded, comparing the two revealed the TOTP code replay as the only difference.

### What Didn't Work

1. **Looking at JMeter summary statistics only**: The 40% error rate pointed to Steps 2b and 3, not the real culprit (Step 2c). Statistics can be misleading when assertions don't properly detect failures.

2. **Trying to capture response headers via JTL save properties**: `jmeter.save.saveservice.response_headers=true` didn't reliably capture headers in XML format. Direct logging via JSR223 was more reliable.

3. **Assuming the failing step was the root cause**: Step 2b was reported as failing, but the real issue was upstream at Step 2c. Always trace back to the first point of divergence.

### Debugging Checklist for Auth Flow Tests

```
1. Does iteration 1 succeed? If yes, the flow logic is correct.
2. Does iteration 2 fail? If yes, something changes between iterations.
3. What changes between iterations?
   - Time (TOTP window might be the same)
   - Cookies (are they cleared? JMeter CookieManager.clearEachIteration)
   - Server-side session state
   - Rate limiting
4. For each step, log the FULL redirect Location header, not just status code.
5. Check for "authFailure" or error indicators in redirect URLs.
6. Verify correlation variables are correct (not extracted from error redirects).
```

---

## 13. Key Takeaways

### For WSO2 IS TOTP Integration

1. **TOTP enrollment field is `verificationCode`**, not `verifyCode`
2. **Basic Auth is blocked** for `/api/users/v1/me/totp` - use Bearer tokens
3. **Get the Bearer token BEFORE INIT** - INIT sets `totpEnabled=true` which blocks password grant
4. **IS has TOTP replay protection** in the `/commonauth` authentication flow - same code rejected twice in same 30s window

### For JMeter Performance Testing

5. **Never assert only on HTTP status codes for auth flows** - check redirect destinations and error indicators
6. **Add debug logging PostProcessors** during development - they're the fastest way to diagnose auth flow issues
7. **Account for TOTP replay protection** - add a replay guard or create enough users to avoid code collisions
8. **Each thread needs a unique user** for TOTP tests - shared users will have code collisions
9. **Use `CookieManager.clearEachIteration=true`** for auth flows - stale cookies cause unexpected behavior

### For Shell Scripting

10. **Avoid Bash string interpolation with passwords** - use Python for JSON generation
11. **Use `curl -d @file.json`** pattern instead of inline JSON with special characters
12. **macOS BSD utilities differ from GNU** - `head -n -1` doesn't work on macOS

### For Debugging

13. **Trace failures back to the first point of divergence** - the reported failing step may not be the root cause
14. **Compare succeeding vs. failing iterations** to identify what changed
15. **Statistics can mask root causes** - a 40% error rate that looks like Steps 2b+3 failing is actually Step 2c failing silently
16. **When in doubt, log everything** and analyze the raw data rather than relying on pass/fail assertions

---

## Appendix: File Reference

| File | Purpose |
|------|---------|
| `scenarios/Adaptive_Script_TOTP_Flow.jmx` | Main JMeter test plan for TOTP MFA auth flow |
| `setup/setup_totp_users.sh` | Shell script to create and enroll N users in TOTP |
| `setup/TestData_Enroll_TOTP.jmx` | Legacy JMeter enrollment setup (older IS versions) |
| `testdata/totp_users.csv` | Generated CSV with username, password, TOTP secret per user |
| `config.properties` | IS connection details, OAuth app credentials, test parameters |
| `run-local-tests.sh` | Test runner script (handles JMeter invocation, SSL, reporting) |

---

*Report generated from debugging sessions on WSO2 IS 7.2.1-SNAPSHOT with Apache JMeter 5.6.3*
