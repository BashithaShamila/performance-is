#!/bin/bash -e
# ============================================================
# Setup: Create Role-Based Users for Adaptive Script Load Testing
# ============================================================
# Creates users with admin, manager, and employee application roles.
# Enrolls TOTP for admin and manager users (they hit step 2).
# Employee users only go through step 1 (password).
#
# The adaptive script under test:
#   - Step 1: Password (all users)
#   - Step 2: TOTP (only for admin/manager roles via hasAnyOfTheRolesV2)
#
# Usage:
#   ./setup/setup_role_users.sh              # 5 admin, 5 manager, 5 employee
#   ./setup/setup_role_users.sh 10           # 10 of each role (30 total)
#   ./setup/setup_role_users.sh 10 20 15     # 10 admin, 20 manager, 15 employee
#
# Output: testdata/role_users.csv
#   username,password,totpSecret,role
#   role_admin_1,Test@1234!,SECRET...,admin
#   role_manager_1,Test@1234!,SECRET...,manager
#   role_employee_1,Test@1234!,,employee
# ============================================================

SCRIPT_DIR=$(dirname "$0")
CONFIG_FILE="$SCRIPT_DIR/../config.properties"
TESTDATA_DIR="$SCRIPT_DIR/../testdata"
CSV_FILE="$TESTDATA_DIR/role_users.csv"

# ---- Parse arguments ----
if [ $# -eq 1 ]; then
    ADMIN_COUNT="$1"
    MANAGER_COUNT="$1"
    EMPLOYEE_COUNT="$1"
elif [ $# -eq 3 ]; then
    ADMIN_COUNT="$1"
    MANAGER_COUNT="$2"
    EMPLOYEE_COUNT="$3"
else
    ADMIN_COUNT=5
    MANAGER_COUNT=5
    EMPLOYEE_COUNT=5
fi

# ---- Read config ----
IS_HOST=$(grep -E "^host=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
IS_PORT=$(grep -E "^port=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
ADMIN_CRED=$(grep -E "^adminCredentials=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
TEST_PASSWORD=$(grep -E "^testPassword=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')
IS_HOME=$(grep -E "^isHome=" "$CONFIG_FILE" | cut -d= -f2- | tr -d ' ')
CLIENT_ID=$(grep -E "^clientId=" "$CONFIG_FILE" | cut -d= -f2 | tr -d ' ')

IS_BASE="https://${IS_HOST}:${IS_PORT}"
TOTAL_COUNT=$((ADMIN_COUNT + MANAGER_COUNT + EMPLOYEE_COUNT))

echo "============================================================"
echo "  Role-Based User Setup (IS 7.2.x)"
echo "  IS: $IS_BASE"
echo "  Admin users:    $ADMIN_COUNT"
echo "  Manager users:  $MANAGER_COUNT"
echo "  Employee users: $EMPLOYEE_COUNT"
echo "  Total:          $TOTAL_COUNT"
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

# ---- Find the application ID for the OAuth app ----
echo ""
echo "Looking up application for clientId: $CLIENT_ID ..."
APP_ID=$(curl -s $CURL_SSL \
    "${IS_BASE}/api/server/v1/applications" \
    -H "Authorization: Basic $ADMIN_CRED" | \
    python3 -c "
import sys, json
d = json.load(sys.stdin)
for app in d.get('applications', []):
    print(app['id'])
" 2>/dev/null | while read aid; do
    # Check each app's OIDC config for matching clientId
    cid=$(curl -s $CURL_SSL \
        "${IS_BASE}/api/server/v1/applications/${aid}/inbound-protocols/oidc" \
        -H "Authorization: Basic $ADMIN_CRED" 2>/dev/null | \
        python3 -c "import sys,json; print(json.load(sys.stdin).get('clientId',''))" 2>/dev/null)
    if [ "$cid" = "$CLIENT_ID" ]; then
        echo "$aid"
        break
    fi
done)

if [ -z "$APP_ID" ]; then
    echo "ERROR: Could not find application with clientId=$CLIENT_ID"
    exit 1
fi
echo "Application ID: $APP_ID"

# ---- Create application roles (admin, manager, employee) ----
echo ""
echo "Creating application roles..."
ADMIN_ROLE_ID=""
MANAGER_ROLE_ID=""
EMPLOYEE_ROLE_ID=""

for role_name in admin manager employee; do
    # Check if role already exists
    EXISTING=$(curl -s $CURL_SSL \
        "${IS_BASE}/scim2/v2/Roles?filter=displayName+eq+${role_name}+and+audience.value+eq+${APP_ID}" \
        -H "Authorization: Basic $ADMIN_CRED" | \
        python3 -c "
import sys, json
d = json.load(sys.stdin)
resources = d.get('Resources', [])
for r in resources:
    aud = r.get('audience', {})
    if aud.get('value') == '$APP_ID':
        print(r['id'])
        break
" 2>/dev/null)

    if [ -n "$EXISTING" ]; then
        ROLE_ID="$EXISTING"
        echo "  $role_name: exists ($ROLE_ID)"
    else
        ROLE_ID=$(curl -s $CURL_SSL -X POST "${IS_BASE}/scim2/v2/Roles" \
            -H "Authorization: Basic $ADMIN_CRED" \
            -H "Content-Type: application/json" \
            -d "{\"displayName\": \"$role_name\", \"audience\": {\"value\": \"$APP_ID\", \"type\": \"application\"}}" | \
            python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
        echo "  $role_name: created ($ROLE_ID)"
    fi

    case "$role_name" in
        admin)    ADMIN_ROLE_ID="$ROLE_ID" ;;
        manager)  MANAGER_ROLE_ID="$ROLE_ID" ;;
        employee) EMPLOYEE_ROLE_ID="$ROLE_ID" ;;
    esac
done

# ---- Find or create TOTPEnrollClient ----
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
fi

ENROLL_OIDC=$(curl -s $CURL_SSL \
    "${IS_BASE}/api/server/v1/applications/${ENROLL_APP}/inbound-protocols/oidc" \
    -H "Authorization: Basic $ADMIN_CRED")
ENROLL_CLIENT_ID=$(echo "$ENROLL_OIDC" | python3 -c "import sys,json; print(json.load(sys.stdin)['clientId'])" 2>/dev/null)
ENROLL_CLIENT_SECRET=$(echo "$ENROLL_OIDC" | python3 -c "import sys,json; print(json.load(sys.stdin)['clientSecret'])" 2>/dev/null)
echo "TOTPEnrollClient: $ENROLL_CLIENT_ID"

# ---- Write CSV header ----
echo "username,password,totpSecret,role" > "$CSV_FILE"

# ---- Helper: create user, assign role, optionally enroll TOTP ----
SUCCESS_COUNT=0
FAIL_COUNT=0

create_user() {
    local username="$1"
    local role_name="$2"
    local enroll_totp="$3"  # "true" or "false"
    local role_id=""
    case "$role_name" in
        admin)    role_id="$ADMIN_ROLE_ID" ;;
        manager)  role_id="$MANAGER_ROLE_ID" ;;
        employee) role_id="$EMPLOYEE_ROLE_ID" ;;
    esac

    # Delete existing user
    EXISTING_ID=$(curl -s $CURL_SSL "${IS_BASE}/scim2/Users?filter=userName+eq+${username}" \
        -H "Authorization: Basic $ADMIN_CRED" | \
        python3 -c "import sys,json; u=json.load(sys.stdin).get('Resources',[]); print(u[0]['id'] if u else '')" 2>/dev/null)

    if [ -n "$EXISTING_ID" ]; then
        curl -s $CURL_SSL -X DELETE "${IS_BASE}/scim2/Users/$EXISTING_ID" \
            -H "Authorization: Basic $ADMIN_CRED" -o /dev/null
    fi

    # Create user
    python3 -c "
import json
print(json.dumps({
    'schemas': ['urn:ietf:params:scim:schemas:core:2.0:User'],
    'userName': '${username}',
    'password': '${TEST_PASSWORD}',
    'name': {'givenName': '${role_name}', 'familyName': 'User'},
    'emails': [{'primary': True, 'value': '${username}@example.com'}]
}))
" > /tmp/role_create_user.json

    CREATE_RESP=$(curl -s $CURL_SSL -X POST "${IS_BASE}/scim2/Users" \
        -H "Authorization: Basic $ADMIN_CRED" \
        -H "Content-Type: application/json" \
        -d @/tmp/role_create_user.json)
    USER_ID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    if [ -z "$USER_ID" ]; then
        echo "  ERROR creating user: $CREATE_RESP"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi

    # Assign application role
    curl -s $CURL_SSL -X PATCH "${IS_BASE}/scim2/v2/Roles/$role_id" \
        -H "Authorization: Basic $ADMIN_CRED" \
        -H "Content-Type: application/json" \
        -d "{\"Operations\": [{\"op\": \"add\", \"path\": \"users\", \"value\": [{\"value\": \"$USER_ID\"}]}]}" -o /dev/null

    # Enroll TOTP if needed (admin/manager)
    if [ "$enroll_totp" = "true" ]; then
        # Get Bearer token BEFORE INIT
        BEARER_TOKEN=$(curl -s $CURL_SSL -X POST "${IS_BASE}/oauth2/token" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            --data-urlencode "grant_type=password" \
            --data-urlencode "username=${username}" \
            --data-urlencode "password=${TEST_PASSWORD}" \
            --data-urlencode "client_id=${ENROLL_CLIENT_ID}" \
            --data-urlencode "client_secret=${ENROLL_CLIENT_SECRET}" \
            --data-urlencode "scope=internal_login" | \
            python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

        if [ -z "$BEARER_TOKEN" ]; then
            echo "  ERROR: Could not get Bearer token for $username"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return 1
        fi

        # INIT TOTP
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
            echo "  ERROR: TOTP INIT failed for $username: $INIT_RESP"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return 1
        fi

        # VALIDATE TOTP
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

        if [ "$IS_VALID" != "True" ]; then
            echo "  ERROR: TOTP VALIDATE failed for $username: $VAL_RESP"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return 1
        fi

        echo "  $username | role=$role_name | TOTP enrolled"
        echo "${username},${TEST_PASSWORD},${TOTP_SECRET},${role_name}" >> "$CSV_FILE"
    else
        echo "  $username | role=$role_name | no TOTP"
        echo "${username},${TEST_PASSWORD},,${role_name}" >> "$CSV_FILE"
    fi

    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    return 0
}

# ---- Create users per role ----
echo ""
echo "--- Creating admin users (TOTP enrolled) ---"
for i in $(seq 1 $ADMIN_COUNT); do
    create_user "role_admin_${i}" "admin" "true" || true
done

echo ""
echo "--- Creating manager users (TOTP enrolled) ---"
for i in $(seq 1 $MANAGER_COUNT); do
    create_user "role_manager_${i}" "manager" "true" || true
done

echo ""
echo "--- Creating employee users (no TOTP) ---"
for i in $(seq 1 $EMPLOYEE_COUNT); do
    create_user "role_employee_${i}" "employee" "false" || true
done

echo ""
echo "============================================================"
echo "  Done: $SUCCESS_COUNT succeeded, $FAIL_COUNT failed"
echo "  CSV: $CSV_FILE"
echo "============================================================"
cat "$CSV_FILE"
echo ""

if [ "$SUCCESS_COUNT" -gt 0 ]; then
    echo "Run the role-based test:"
    echo "  ./run-local-tests.sh --skip-setup scenarios/Adaptive_Script_TOTP_Flow.jmx"
else
    echo "ERROR: No users were created. Check IS is running and try again."
    exit 1
fi
