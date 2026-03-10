#!/bin/bash -e
# ============================================================
# Setup: Create and Enroll N Test Users for TOTP Load Testing
# ============================================================
# Each JMeter thread needs its own user + TOTP secret so that
# concurrent threads don't share the same 6-digit code in the
# same 30-second window (TOTP replay protection).
#
# Enrollment flow per user (IS 7.2.x API):
#   1. Create user via SCIM2
#   2. Get Bearer token via TOTPEnrollClient (password grant)
#      (Must be obtained BEFORE INIT, because INIT sets totpEnabled=true)
#   3. POST /api/users/v1/me/totp {"action":"INIT"}  -> returns QR code with secret
#   4. POST /api/users/v1/me/totp {"action":"VALIDATE","verificationCode":"XXXXXX"}
#      -> completes enrollment, persists the TOTP secret in IS
#   5. Write username,password,secret to CSV
#
# Usage:
#   ./setup/setup_totp_users.sh              # Creates 5 users
#   ./setup/setup_totp_users.sh 10           # Creates 10 users
#
# Output: testdata/totp_users.csv
#   username,password,totpSecret
#   adaptive_totp_user_1,Test@1234!,SECRETABC...
# ============================================================

SCRIPT_DIR=$(dirname "$0")
CONFIG_FILE="$SCRIPT_DIR/../config.properties"
TESTDATA_DIR="$SCRIPT_DIR/../testdata"
CSV_FILE="$TESTDATA_DIR/totp_users.csv"

# ---- Read config ----
IS_HOST=$(grep -E "^host=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
IS_PORT=$(grep -E "^port=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
ADMIN_CRED=$(grep -E "^adminCredentials=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
TEST_PASSWORD=$(grep -E "^testPassword=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
IS_HOME=$(grep -E "^isHome=" "$CONFIG_FILE" | cut -d= -f2- | tr -d ' ')

IS_BASE="https://${IS_HOST}:${IS_PORT}"
USER_COUNT="${1:-5}"

echo "============================================================"
echo "  TOTP Multi-User Setup (IS 7.2.x API)"
echo "  IS: $IS_BASE"
echo "  Users to create: $USER_COUNT"
echo "  Output: $CSV_FILE"
echo "============================================================"

# ---- SSL options for curl ----
TRUSTSTORE="$IS_HOME/repository/resources/security/wso2carbon.jks"
if [ -f "$TRUSTSTORE" ]; then
    PEM_CERT="/tmp/wso2carbon.pem"
    keytool -export -alias wso2carbon -keystore "$TRUSTSTORE" \
        -storepass wso2carbon -file /tmp/wso2carbon.cer -noprompt 2>/dev/null || true
    openssl x509 -inform DER -in /tmp/wso2carbon.cer -out "$PEM_CERT" 2>/dev/null || true
    if [ -f "$PEM_CERT" ]; then
        CURL_SSL="--cacert $PEM_CERT"
        echo "Using IS certificate for SSL verification."
    else
        CURL_SSL="-k"
        echo "WARNING: Could not extract IS cert, skipping SSL verification."
    fi
else
    CURL_SSL="-k"
    echo "WARNING: IS truststore not found, skipping SSL verification."
fi

mkdir -p "$TESTDATA_DIR"

# ---- Find or create the TOTPEnrollClient OAuth2 app ----
echo ""
echo "Looking for TOTPEnrollClient app..."
ENROLL_APP=$(curl -s $CURL_SSL \
    "${IS_BASE}/api/server/v1/applications?filter=name+eq+TOTPEnrollClient" \
    -H "Authorization: Basic $ADMIN_CRED" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); apps=d.get('applications',[]); print(apps[0]['id'] if apps else '')" 2>/dev/null)

if [ -z "$ENROLL_APP" ]; then
    echo "Creating TOTPEnrollClient OAuth2 application..."
    python3 -c "
import json
print(json.dumps({
    'name': 'TOTPEnrollClient',
    'inboundProtocolConfiguration': {
        'oidc': {'grantTypes': ['password'], 'publicClient': False}
    }
}))
" > /tmp/totp_enroll_app.json
    ENROLL_APP=$(curl -s $CURL_SSL -X POST "${IS_BASE}/api/server/v1/applications" \
        -H "Authorization: Basic $ADMIN_CRED" \
        -H "Content-Type: application/json" \
        -d @/tmp/totp_enroll_app.json | \
        python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
    echo "Created app ID: $ENROLL_APP"
fi

# ---- Get the password-grant client credentials ----
ENROLL_OIDC=$(curl -s $CURL_SSL \
    "${IS_BASE}/api/server/v1/applications/${ENROLL_APP}/inbound-protocols/oidc" \
    -H "Authorization: Basic $ADMIN_CRED")
ENROLL_CLIENT_ID=$(echo "$ENROLL_OIDC" | python3 -c "import sys,json; print(json.load(sys.stdin)['clientId'])" 2>/dev/null)
ENROLL_CLIENT_SECRET=$(echo "$ENROLL_OIDC" | python3 -c "import sys,json; print(json.load(sys.stdin)['clientSecret'])" 2>/dev/null)
echo "TOTPEnrollClient: $ENROLL_CLIENT_ID"

# ---- Write CSV header ----
echo "username,password,totpSecret" > "$CSV_FILE"

# ---- Process each user ----
SUCCESS_COUNT=0
FAIL_COUNT=0

for i in $(seq 1 $USER_COUNT); do
    USERNAME="adaptive_totp_user_${i}"
    echo ""
    echo "--- User $i/$USER_COUNT: $USERNAME ---"

    # Step 1: Delete existing user (if any) and recreate fresh.
    #   This ensures a clean state (no totpEnabled, no locked account).
    EXISTING_ID=$(curl -s $CURL_SSL "${IS_BASE}/scim2/Users?filter=userName+eq+${USERNAME}" \
        -H "Authorization: Basic $ADMIN_CRED" | \
        python3 -c "import sys,json; u=json.load(sys.stdin).get('Resources',[]); print(u[0]['id'] if u else '')" 2>/dev/null)

    if [ -n "$EXISTING_ID" ]; then
        curl -s $CURL_SSL -X DELETE "${IS_BASE}/scim2/Users/$EXISTING_ID" \
            -H "Authorization: Basic $ADMIN_CRED" -o /dev/null
        echo "  [1/4] Deleted existing user"
    fi

    # Create user via JSON file (avoids bash ! escaping issues)
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

    CREATE_RESP=$(curl -s $CURL_SSL -X POST "${IS_BASE}/scim2/Users" \
        -H "Authorization: Basic $ADMIN_CRED" \
        -H "Content-Type: application/json" \
        -d @/tmp/totp_create_user.json)
    USER_ID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    if [ -z "$USER_ID" ]; then
        echo "  [1/4] ERROR creating user: $CREATE_RESP"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    echo "  [1/4] User created ($USER_ID)"

    # Step 2: Get Bearer token via password grant.
    #   MUST be obtained now, before INIT sets totpEnabled=true
    #   (after that, password grant fails because IS requires TOTP completion).
    BEARER_TOKEN=$(curl -s $CURL_SSL -X POST "${IS_BASE}/oauth2/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "grant_type=password" \
        --data-urlencode "username=${USERNAME}" \
        --data-urlencode "password=${TEST_PASSWORD}" \
        --data-urlencode "client_id=${ENROLL_CLIENT_ID}" \
        --data-urlencode "client_secret=${ENROLL_CLIENT_SECRET}" \
        --data-urlencode "scope=internal_login" | \
        python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

    if [ -z "$BEARER_TOKEN" ]; then
        echo "  [2/4] ERROR: Could not get Bearer token, skipping"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    echo "  [2/4] Bearer token obtained"

    # Step 3: INIT enrollment — generates TOTP secret and sets totpEnabled=true.
    #   Also sets the pending secret that VALIDATE will confirm.
    INIT_RESP=$(curl -s $CURL_SSL -X POST "${IS_BASE}/api/users/v1/me/totp" \
        -H "Authorization: Bearer $BEARER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"action":"INIT"}')

    TOTP_SECRET=$(python3 -c "
import json, base64, sys
from urllib.parse import urlparse, parse_qs
try:
    d = json.loads(sys.argv[1])
    uri = base64.b64decode(d['qrCodeUrl']).decode()
    print(parse_qs(urlparse(uri).query)['secret'][0])
except Exception as e:
    print('', end='')
    print(f'ERROR: {e}', file=sys.stderr)
" "$INIT_RESP" 2>/dev/null)

    if [ -z "$TOTP_SECRET" ]; then
        echo "  [3/4] ERROR: INIT failed: $INIT_RESP"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    echo "  [3/4] INIT done, secret: $TOTP_SECRET"

    # Step 4: VALIDATE — generate TOTP code and confirm enrollment.
    #   Uses the SAME Bearer token (still valid despite totpEnabled=true).
    TOTP_CODE=$(python3 -c "
import hmac, hashlib, time, struct, base64, sys
secret = sys.argv[1]
key = base64.b32decode(secret + '=' * (-(len(secret)) % 8))
t = int(time.time()) // 30
h = hmac.new(key, struct.pack('>Q', t), hashlib.sha1).digest()
o = h[-1] & 0xf
print(str((struct.unpack('>I', h[o:o+4])[0] & 0x7fffffff) % 1000000).zfill(6))
" "$TOTP_SECRET" 2>/dev/null)

    VAL_RESP=$(curl -s $CURL_SSL -X POST "${IS_BASE}/api/users/v1/me/totp" \
        -H "Authorization: Bearer $BEARER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"VALIDATE\",\"verificationCode\":\"$TOTP_CODE\"}")
    IS_VALID=$(echo "$VAL_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('isValid',''))" 2>/dev/null)

    if [ "$IS_VALID" = "True" ]; then
        echo "  [4/4] VALIDATE successful — enrollment persisted"
        echo "${USERNAME},${TEST_PASSWORD},${TOTP_SECRET}" >> "$CSV_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  [4/4] ERROR: VALIDATE failed: $VAL_RESP"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo ""
echo "============================================================"
echo "  Done: $SUCCESS_COUNT succeeded, $FAIL_COUNT failed"
echo "  CSV written to: $CSV_FILE"
echo "============================================================"
cat "$CSV_FILE"
echo ""

if [ "$SUCCESS_COUNT" -gt 0 ]; then
    echo "Run the TOTP scenario with:"
    echo "  ./run-local-tests.sh --skip-setup scenarios/Adaptive_Script_TOTP_Flow.jmx"
else
    echo "ERROR: No users were enrolled. Check IS is running and try again."
    exit 1
fi
