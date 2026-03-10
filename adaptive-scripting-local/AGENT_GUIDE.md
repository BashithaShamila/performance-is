# Performance Testing Agent Guide

Step-by-step guide for running adaptive script performance tests on this machine, comparing the **Default IS pack** vs **Updated IS pack** (with remote GraalJS engine).

---

## Machine-Specific Paths

| Item | Path |
|------|------|
| **Test Framework** | `/Users/bashitha/Downloads/product/performance test/performance-is/adaptive-scripting-local/` |
| **Default IS Pack** | `/Users/bashitha/Downloads/product/Default pack/wso2is-7.2.1-SNAPSHOT` |
| **Updated IS Pack** | `/Users/bashitha/Downloads/product/wso2is-7.2.1-SNAPSHOT` |

---

## Pack-Specific OAuth Credentials

Each IS pack has its own `AdaptiveScriptJMeterTest` OAuth application with different credentials. You **must** update `config.properties` when switching packs.

### Default Pack

```properties
clientId=plAJCI5t9D6DSg24bsGMQztVT6sa
clientSecret=RAyLQ8DxNNRZCADqRMyWEsG5ovat9KITt5iYs_QfVfAa
isHome=/Users/bashitha/Downloads/product/Default pack/wso2is-7.2.1-SNAPSHOT
```

### Updated Pack

```properties
clientId=HqfysAhVLVIE4TfX5pAOMGTXAaUa
clientSecret=qKoCdSJu8ud9P1QanRC2pdfeRx7JlXV640eI4pUHrZEa
isHome=/Users/bashitha/Downloads/product/wso2is-7.2.1-SNAPSHOT
```

---

## Initial Setup (One-Time Per Pack)

These steps were already completed for both packs on this machine. Only repeat if you recreate a pack from scratch.

### 1. Start the IS Pack

```bash
# Default pack
/Users/bashitha/Downloads/product/Default\ pack/wso2is-7.2.1-SNAPSHOT/bin/wso2server.sh

# Updated pack
/Users/bashitha/Downloads/product/wso2is-7.2.1-SNAPSHOT/bin/wso2server.sh
```

Wait for startup to complete (console shows "WSO2 Carbon started").

### 2. Create the OAuth Application

If `AdaptiveScriptJMeterTest` doesn't exist on the pack:

```bash
# Create the app via API
curl -sk -X POST "https://localhost:9443/api/server/v1/applications" \
    -H "Authorization: Basic YWRtaW46YWRtaW4=" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "AdaptiveScriptJMeterTest",
        "inboundProtocolConfiguration": {
            "oidc": {
                "grantTypes": ["authorization_code", "password"],
                "callbackURLs": ["https://localhost/callback"],
                "publicClient": false
            }
        }
    }'

# Get the app ID
APP_ID=$(curl -sk https://localhost:9443/api/server/v1/applications \
    -H "Authorization: Basic YWRtaW46YWRtaW4=" | \
    python3 -c "import sys,json; [print(a['id']) for a in json.load(sys.stdin)['applications'] if a['name']=='AdaptiveScriptJMeterTest']")

# Get the credentials (copy these to config.properties)
curl -sk "https://localhost:9443/api/server/v1/applications/${APP_ID}/inbound-protocols/oidc" \
    -H "Authorization: Basic YWRtaW46YWRtaW4=" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(f'clientId={d[\"clientId\"]}'); print(f'clientSecret={d[\"clientSecret\"]}')"
```

### 3. Add Authentication Steps (Step 1: Password, Step 2: TOTP)

```bash
APP_ID="<app-id-from-above>"

curl -sk -X PATCH "https://localhost:9443/api/server/v1/applications/${APP_ID}" \
    -H "Authorization: Basic YWRtaW46YWRtaW4=" \
    -H "Content-Type: application/json" \
    -d '{
        "authenticationSequence": {
            "type": "USER_DEFINED",
            "steps": [
                {"id": 1, "options": [{"idp": "LOCAL", "authenticator": "BasicAuthenticator"}]},
                {"id": 2, "options": [{"idp": "LOCAL", "authenticator": "totp"}]}
            ],
            "subjectStepId": 1,
            "attributeStepId": 1,
            "script": "var onLoginRequest = function(context) {\n    executeStep(1, {\n        onSuccess: function(context) {\n            executeStep(2);\n        }\n    });\n};"
        }
    }'
```

Then go to the IS Console (`https://localhost:9443/console`) > Applications > AdaptiveScriptJMeterTest > Login Flow and replace the script with your actual role-based adaptive script.

### 4. Create Role-Based Users

Update `config.properties` with the correct pack credentials first, then:

```bash
cd "/Users/bashitha/Downloads/product/performance test/performance-is/adaptive-scripting-local"

# Create 50 of each role (150 total)
./setup/setup_role_users.sh 50

# Or create 1000 employees only (for high-concurrency tests)
./setup/setup_role_users.sh 0 0 1000
```

This creates:
- Application roles (`admin`, `manager`, `employee`) scoped to `AdaptiveScriptJMeterTest`
- Users with format `role_admin_N`, `role_manager_N`, `role_employee_N`
- TOTP enrolled for admin and manager users
- Output: `testdata/role_users.csv`

### 5. Shuffle CSV for Mixed-Role Testing

```bash
python3 -c "
import random
with open('testdata/role_users.csv') as f:
    lines = f.readlines()
header = lines[0]
data = lines[1:]
random.shuffle(data)
with open('testdata/role_users.csv', 'w') as f:
    f.write(header)
    f.writelines(data)
print(f'Shuffled {len(data)} users')
"
```

---

## Switching Between Packs

Every time you switch which IS pack is running, update **three values** in `config.properties`:

```bash
cd "/Users/bashitha/Downloads/product/performance test/performance-is/adaptive-scripting-local"
```

**To switch to Default Pack:**
```
clientId=plAJCI5t9D6DSg24bsGMQztVT6sa
clientSecret=RAyLQ8DxNNRZCADqRMyWEsG5ovat9KITt5iYs_QfVfAa
isHome=/Users/bashitha/Downloads/product/Default pack/wso2is-7.2.1-SNAPSHOT
```

**To switch to Updated Pack:**
```
clientId=HqfysAhVLVIE4TfX5pAOMGTXAaUa
clientSecret=qKoCdSJu8ud9P1QanRC2pdfeRx7JlXV640eI4pUHrZEa
isHome=/Users/bashitha/Downloads/product/wso2is-7.2.1-SNAPSHOT
```

---

## Running Tests

### Filter to Employees Only (Recommended for Clean Benchmarks)

The CSV contains admin/manager/employee users. For pure employee benchmarks, filter first:

```bash
cp testdata/role_users.csv testdata/role_users_backup.csv
head -1 testdata/role_users.csv > /tmp/emp_only.csv
grep ",employee$" testdata/role_users.csv >> /tmp/emp_only.csv
cp /tmp/emp_only.csv testdata/role_users.csv
```

Restore after testing:
```bash
cp testdata/role_users_backup.csv testdata/role_users.csv
```

### Run Commands

```bash
# 50 concurrent users, 2 minutes (quick test)
./run-local-tests.sh --tag <pack>_50emp_2min --skip-setup \
    -Jconcurrency=50 -Jrampup=10 -Jduration=120 \
    scenarios/Adaptive_Script_RoleBased_Flow.jmx

# 50 concurrent users, 10 minutes (standard benchmark)
./run-local-tests.sh --tag <pack>_50emp_10min --skip-setup \
    -Jconcurrency=50 -Jrampup=10 -Jduration=600 \
    scenarios/Adaptive_Script_RoleBased_Flow.jmx

# 200 concurrent users, 10 minutes (stress test)
./run-local-tests.sh --tag <pack>_200emp_10min --skip-setup \
    -Jconcurrency=200 -Jrampup=30 -Jduration=600 \
    scenarios/Adaptive_Script_RoleBased_Flow.jmx

# 1000 concurrent users, 5 minutes (upper limit test)
./run-local-tests.sh --tag <pack>_1000emp_5min --skip-setup \
    -Jconcurrency=1000 -Jrampup=60 -Jduration=300 \
    scenarios/Adaptive_Script_RoleBased_Flow.jmx
```

Replace `<pack>` with `default` or `updated` for clear result labeling.

### Run Per-Role Isolation Tests

To test each role separately (employees first, then admins, then managers):

```bash
# Filter and run employees
head -1 testdata/role_users.csv > /tmp/role.csv
grep ",employee$" testdata/role_users.csv >> /tmp/role.csv
cp /tmp/role.csv testdata/role_users.csv
./run-local-tests.sh --tag employees --skip-setup -Jconcurrency=50 -Jrampup=10 -Jduration=120 scenarios/Adaptive_Script_RoleBased_Flow.jmx

# Filter and run admins
head -1 testdata/role_users_backup.csv > /tmp/role.csv
grep ",admin$" testdata/role_users_backup.csv >> /tmp/role.csv
cp /tmp/role.csv testdata/role_users.csv
./run-local-tests.sh --tag admins --skip-setup -Jconcurrency=50 -Jrampup=10 -Jduration=120 scenarios/Adaptive_Script_RoleBased_Flow.jmx

# Filter and run managers
head -1 testdata/role_users_backup.csv > /tmp/role.csv
grep ",manager$" testdata/role_users_backup.csv >> /tmp/role.csv
cp /tmp/role.csv testdata/role_users.csv
./run-local-tests.sh --tag managers --skip-setup -Jconcurrency=50 -Jrampup=10 -Jduration=120 scenarios/Adaptive_Script_RoleBased_Flow.jmx

# Restore
cp testdata/role_users_backup.csv testdata/role_users.csv
```

---

## Analyzing Results

### Quick Summary from JMeter Output

The test prints a summary at the end showing total samples, error rate, and throughput.

### Per-Step Breakdown

```bash
python3 -c "
import csv, math
from collections import defaultdict

jtl = 'results/<RESULTS_DIR>/Adaptive_Script_RoleBased_Flow.jtl'
data = defaultdict(lambda: {'elapsed': [], 'errors': 0})

with open(jtl) as f:
    for row in csv.DictReader(f):
        d = data[row['label']]
        d['elapsed'].append(int(row['elapsed']))
        if row['success'].strip().lower() == 'false':
            d['errors'] += 1

print(f'{\"Step\":<50} {\"Count\":>7} {\"Err%\":>6} {\"Avg(ms)\":>8} {\"P95(ms)\":>8} {\"Max(ms)\":>8}')
print('-' * 95)
for label in sorted(data):
    d = data[label]
    vals = sorted(d['elapsed'])
    c = len(vals)
    avg = sum(vals)/c
    p95 = vals[int(math.ceil(c*0.95))-1]
    print(f'{label:<50} {c:>7} {d[\"errors\"]/c*100:>5.1f}% {avg:>8.0f} {p95:>8} {vals[-1]:>8}')
"
```

### Error Analysis (When Errors Occur)

```bash
python3 -c "
import csv
from collections import Counter

jtl = 'results/<RESULTS_DIR>/Adaptive_Script_RoleBased_Flow.jtl'
errors = Counter()
with open(jtl) as f:
    for row in csv.DictReader(f):
        if row['success'].strip().lower() == 'false':
            fail = row.get('failureMessage', '')[:100]
            errors[f\"{row['label']} | {fail}\"] += 1

for k, v in errors.most_common(20):
    print(f'  {v:>6}x  {k}')
"
```

### Compare Two Runs

```bash
./compare-results.sh results/<run_A> results/<run_B>
```

### HTML Report

Each test generates an HTML report at:
```
results/<tag>_YYYYMMDD_HHMMSS/html-report/index.html
```

---

## Benchmark Results (This Machine)

### Employee-Only (Password + Adaptive Script, No TOTP)

| Concurrency | Duration | Default Pack | Updated Pack |
|-------------|----------|-------------|-------------|
| **50** | 10 min | 0.00% err, 480 req/s, 57ms avg | 0.00% err, 193-200 req/s, 244-253ms avg |
| **200** | 10 min | 0.00% err, 371 req/s, 467ms avg | 64% err (cache eviction) |
| **1000** | 5 min | 0.00% err, 291 req/s, 3015ms avg | Not tested |

### Per-Step Latency (50 Concurrent, Updated Pack)

| Step | Description | Avg Response |
|------|-------------|-------------|
| Step 1 | GET /oauth2/authorize (script eval) | ~455ms |
| Step 2 | POST /commonauth - password (script eval) | ~503ms |
| Step 2b | GET /oauth2/authorize - post-auth | ~9ms |
| Step 3 | POST /oauth2/token | ~9ms |

Steps 1 and 2 involve adaptive script evaluation via the remote engine (~450-500ms). Steps 2b and 3 are plain OAuth redirects (~9ms). On the default pack, steps 1 and 2 take ~25ms each (local GraalJS).

### Key Finding: Cache Eviction at High Concurrency

At 200+ concurrent users on the updated pack, the `AuthenticationContextCache` (capacity=5000) overflows because the remote engine's slower response times cause sessions to pile up. Symptoms:
- `authFailure=true` in 7ms (instant rejection, not timeout)
- Fix: Increase cache capacity in `identity.xml` or `deployment.toml`

---

## Test Scenarios Reference

| Scenario JMX | Flow | CSV Required |
|-------------|------|-------------|
| `Adaptive_Script_Login_Flow.jmx` | Password only (no adaptive step 2) | Single test user from config |
| `Adaptive_Script_TOTP_Flow.jmx` | Password + TOTP (all users) | `testdata/totp_users.csv` |
| `Adaptive_Script_RoleBased_Flow.jmx` | Conditional: password → TOTP only for admin/manager | `testdata/role_users.csv` |

---

## Troubleshooting

### "Could not find application with clientId=..."
You have the wrong pack's credentials in `config.properties`. Check which IS pack is running and update `clientId`, `clientSecret`, and `isHome`.

### High Error Rate with `authFailure=true` in <100ms
Cache eviction issue. Either reduce concurrency or increase `AuthenticationContextCache` capacity.

### TOTP Step Fails for Managers but Not Admins
The manager adaptive script path has a memory crash (`new Array(1000000).join(...)`) that crashes the GraalJS `onSuccess` handler. The TOTP validates but the flow never completes.

### 30s Socket Timeouts
IS server is overloaded. Reduce concurrency or check IS heap/thread pool settings.

### "No CSV found" Error
Run the setup script first: `./setup/setup_role_users.sh 50`
