# Adaptive Scripting - Local Performance Tests

Local JMeter performance test suite for WSO2 IS adaptive scripting. Run identical tests against two IS packs (default vs updated) and compare response times. No AWS, no SSH, no cluster — just a local IS instance and JMeter.

## Directory Structure

```
adaptive-scripting-local/
├── config.properties                          ← Edit once per IS pack
├── run-local-tests.sh                         ← Main test runner
├── compare-results.sh                         ← A/B comparison tool
├── setup/
│   ├── TestData_Create_Test_User.jmx          ← Creates test user in IS
│   └── setup_totp_users.sh                    ← Creates N users + enrolls TOTP
├── scenarios/
│   ├── Adaptive_Script_Login_Flow.jmx         ← Password-only OIDC flow
│   └── Adaptive_Script_TOTP_Flow.jmx          ← Password + TOTP MFA flow
├── testdata/
│   └── totp_users.csv.example                 ← Expected CSV format
└── docs/
    └── TOTP_Performance_Test_Learning_Report.md
```

## Prerequisites

1. **WSO2 IS 7.2.x** running locally
2. **Apache JMeter 5.5+** on PATH or in `~/apache-jmeter-*/`
3. **Python 3** (for TOTP setup script only)

---

## One-Time Setup

### 1. Create the OAuth2 Application in IS

Via IS Console (`https://localhost:9443/console`):

1. **Applications > New Application > Standard Based > OAuth2/OIDC**
2. Set **Allowed grant types**: Authorization Code
3. Set **Authorized redirect URLs**: `https://localhost/callback`
4. Configure your **Adaptive Authentication Script** under **Sign-in Method**
5. Copy the **Client ID** and **Client Secret**

### 2. Update `config.properties`

```properties
clientId=<your-client-id>
clientSecret=<your-client-secret>
isHome=/path/to/wso2is-7.x.x
tag=default
```

### 3. TOTP Setup (only for TOTP scenario)

```sh
./setup/setup_totp_users.sh        # Creates 5 users (default)
./setup/setup_totp_users.sh 20     # Creates 20 users
```

This generates `testdata/totp_users.csv` with username, password, and TOTP secret per user.

---

## Running Tests

### Password-only flow (default):
```sh
./run-local-tests.sh
```

### TOTP MFA flow:
```sh
./run-local-tests.sh --skip-setup scenarios/Adaptive_Script_TOTP_Flow.jmx
```

### Tag results for comparison:
```sh
./run-local-tests.sh --tag default --skip-setup scenarios/Adaptive_Script_Login_Flow.jmx
```

### Other flags:
```sh
./run-local-tests.sh --setup-only                    # Only create test user
./run-local-tests.sh --skip-setup scenarios/X.jmx    # Skip setup, run scenario
```

Results and HTML reports are saved to `results/<tag>_YYYYMMDD_HHMMSS/`.

---

## A/B Comparison Workflow

Compare performance between a default IS pack and your updated IS pack:

```sh
# 1. Start default IS pack, run tests
./run-local-tests.sh --tag default --skip-setup scenarios/Adaptive_Script_Login_Flow.jmx

# 2. Stop default IS, start updated IS pack, run same tests
./run-local-tests.sh --tag updated --skip-setup scenarios/Adaptive_Script_Login_Flow.jmx

# 3. Compare results
./compare-results.sh results/default_* results/updated_*
```

The comparison script outputs a markdown table showing per-step metrics:

| Metric | What it shows |
|--------|---------------|
| Avg Response Time | Mean response time per step (ms) |
| P95 Response Time | 95th percentile response time (ms) |
| Delta | Difference between runs (negative = improvement) |
| Error Rate | Percentage of failed requests |

---

## How the Auth Flow Works

```
JMeter                                    WSO2 IS
  |                                          |
  |-- GET /oauth2/authorize?client_id=... -->|
  |<-- 302 login.do?sessionDataKey=KEY ------|
  |                                          |
  |-- POST /commonauth (password)         -->|  ← Adaptive script Step 1
  |<-- 302 to next step or auth code --------|
  |                                          |
  |  (TOTP flow: POST /commonauth + code) -->|  ← Adaptive script Step 2
  |<-- 302 to /oauth2/authorize -------------|
  |                                          |
  |-- GET /t/carbon.super/oauth2/authorize ->|
  |<-- 302 callback?code=AUTH_CODE ----------|
  |                                          |
  |-- POST /oauth2/token (code exchange)  -->|
  |<-- 200 { access_token, id_token } -------|
```

### TOTP Replay Guard

IS rejects the same TOTP code twice in the same 30-second window. The test automatically waits for the next window between iterations. This limits throughput to ~1 auth per 30s per user. Create more users to increase throughput:

```sh
./setup/setup_totp_users.sh 50    # 50 users ≈ 1.67 TPS max
```

---

## Debugging

1. Open JMeter GUI: `jmeter`
2. Open the JMX file
3. Enable **View Results Tree** (right-click > Enable)
4. Set properties and run — inspect each request/response

---

## SSL Certificate

The run script automatically uses the IS truststore if `isHome` is set in `config.properties`. If you see SSL errors, manually import the IS certificate:

```sh
keytool -export -alias wso2carbon \
  -keystore $IS_HOME/repository/resources/security/wso2carbon.jks \
  -file /tmp/wso2carbon.cer -storepass wso2carbon

keytool -import -alias wso2is-local \
  -file /tmp/wso2carbon.cer \
  -keystore "$JAVA_HOME/lib/security/cacerts" \
  -storepass changeit
```
