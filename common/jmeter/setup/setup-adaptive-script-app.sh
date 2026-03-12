#!/bin/bash
# ============================================================
# Setup: Create Adaptive Script App with Role-Based Users
# ============================================================
# Creates an OAuth app with adaptive script authentication,
# application roles (admin, manager, employee), and assigns
# existing isTestUser_{n} users to the employee role.
# Optionally creates dedicated admin/manager/employee users
# and assigns them to their respective application roles.
#
# This script runs on the Bastion node after IS is started.
# It uses IS REST APIs (no console access needed).
#
# Usage:
#   ./setup-adaptive-script-app.sh -h <is_host> -p <is_port> -u <user_count>
#   ./setup-adaptive-script-app.sh -h <is_host> -p <is_port> -u 1000 -m 1000 -a 10
#
# Output: /home/ubuntu/adaptive_app_creds.csv
#         /home/ubuntu/testdata/role_users.csv
# ============================================================

IS_HOST="localhost"
IS_PORT="9443"
USER_COUNT=1000
ADMIN_COUNT=0
MANAGER_COUNT=0
EMPLOYEE_COUNT=0
USE_EXISTING_USERS=true
ADMIN_CRED="YWRtaW46YWRtaW4="
USER_PASSWORD="Password_1"
USERNAME_PREFIX="isTestUser_"
APP_NAME="AdaptiveScriptPerfTestApp"
CALLBACK_URL="https://localhost/callback"
CLIENT_ID_VALUE="adaptiveScriptPerfTestKey"
CLIENT_SECRET_VALUE="adaptiveScriptPerfTestSecret"
CREDS_FILE="/home/ubuntu/adaptive_app_creds.csv"
CSV_DIR="/home/ubuntu/testdata"
CSV_FILE="$CSV_DIR/role_users.csv"

# External microservice URL (optional, for updated pack)
MICROSERVICE_URL=""

function usage() {
    echo ""
    echo "Usage: $0 -h <is_host> -p <is_port> [-u <user_count>] [-a <admin_count>] [-m <manager_count>]"
    echo ""
    echo "-h: IS hostname (default: localhost)"
    echo "-p: IS port (default: 9443)"
    echo "-u: Number of existing users to assign as employees (default: 1000)"
    echo "-a: Number of dedicated admin users to create with TOTP (default: 0)"
    echo "-m: Number of dedicated manager users to create with TOTP (default: 0)"
    echo "-e: Number of dedicated employee users to create (default: 0, uses existing)"
    echo "-x: Username prefix (default: isTestUser_)"
    echo "-w: User password (default: Password_1)"
    echo "-o: Output credentials file path"
    echo "-c: Output CSV file path"
    echo ""
}

while getopts "h:p:u:a:m:e:x:w:o:c:z:" opts; do
    case $opts in
    h) IS_HOST=${OPTARG} ;;
    p) IS_PORT=${OPTARG} ;;
    u) USER_COUNT=${OPTARG} ;;
    a) ADMIN_COUNT=${OPTARG} ;;
    m) MANAGER_COUNT=${OPTARG} ;;
    e) EMPLOYEE_COUNT=${OPTARG} ;;
    x) USERNAME_PREFIX=${OPTARG} ;;
    w) USER_PASSWORD=${OPTARG} ;;
    o) CREDS_FILE=${OPTARG} ;;
    c) CSV_FILE=${OPTARG} ;;
    z) MICROSERVICE_URL=${OPTARG} ;;
    ?) usage; exit 1 ;;
    esac
done

IS_BASE="https://${IS_HOST}:${IS_PORT}"
CURL_SSL="-k"

echo "============================================================"
echo "  Adaptive Script App Setup (IS 7.2.x)"
echo "  IS: $IS_BASE"
echo "  Existing users as employees: $USER_COUNT"
echo "  Dedicated admin users: $ADMIN_COUNT"
echo "  Dedicated manager users: $MANAGER_COUNT"
echo "  Dedicated employee users: $EMPLOYEE_COUNT"
echo "  Credentials: $CREDS_FILE"
echo "  CSV: $CSV_FILE"
echo "============================================================"

mkdir -p "$(dirname "$CREDS_FILE")"
mkdir -p "$CSV_DIR"

# ============================================================
# Pre-flight: Verify IS is reachable
# ============================================================
echo ""
echo "Pre-flight: Checking IS connectivity at $IS_BASE ..."
HEALTH_RESP=$(curl -s -o /dev/null -w "%{http_code}" $CURL_SSL --connect-timeout 10 --max-time 15 "${IS_BASE}/api/server/v1/applications?limit=1" -H "Authorization: Basic $ADMIN_CRED" 2>/dev/null)
if [ "$HEALTH_RESP" = "000" ]; then
    echo "  ERROR: Cannot connect to IS at $IS_BASE (connection refused/timeout)."
    echo "  Check that IS is running and the load balancer (nginx) is configured."
    exit 1
elif [ "$HEALTH_RESP" = "401" ] || [ "$HEALTH_RESP" = "403" ]; then
    echo "  ERROR: IS returned HTTP $HEALTH_RESP — check admin credentials (ADMIN_CRED)."
    exit 1
elif [ "$HEALTH_RESP" != "200" ]; then
    echo "  WARNING: IS returned HTTP $HEALTH_RESP (expected 200). Continuing anyway..."
else
    echo "  IS is reachable (HTTP $HEALTH_RESP)."
fi

# ============================================================
# Step 1: Load Adaptive Script
# ============================================================
echo ""
echo "Step 1: Loading adaptive script ..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ADAPTIVE_SCRIPT_FILE="${ADAPTIVE_SCRIPT_FILE:-$SCRIPT_DIR/adaptive-script.js}"

if [ ! -f "$ADAPTIVE_SCRIPT_FILE" ]; then
    echo "  ERROR: Adaptive script file not found: $ADAPTIVE_SCRIPT_FILE"
    exit 1
fi

echo "  Loading script from: $ADAPTIVE_SCRIPT_FILE"
cat "$ADAPTIVE_SCRIPT_FILE"
echo ""

# Escape the script content for JSON embedding
ADAPTIVE_SCRIPT=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    content = f.read().strip()
print(json.dumps(content)[1:-1])
" "$ADAPTIVE_SCRIPT_FILE")

if [ -z "$ADAPTIVE_SCRIPT" ]; then
    echo "  ERROR: Failed to load/escape adaptive script"
    exit 1
fi
echo "  Adaptive script loaded and escaped for JSON"

# ============================================================
# Step 2: Create OAuth Application (with auth sequence inline)
# ============================================================
echo ""
echo "Step 2: Creating OAuth application: $APP_NAME ..."

# Check if app already exists
LIST_RESP=$(curl -s $CURL_SSL -w "\n%{http_code}" \
    "${IS_BASE}/api/server/v1/applications?filter=name+eq+${APP_NAME}" \
    -H "Authorization: Basic $ADMIN_CRED")
LIST_HTTP_CODE=$(echo "$LIST_RESP" | tail -1)
LIST_BODY=$(echo "$LIST_RESP" | sed '$d')

if [ "$LIST_HTTP_CODE" != "200" ]; then
    echo "  WARNING: App listing returned HTTP $LIST_HTTP_CODE"
    echo "  Response: $LIST_BODY"
fi

EXISTING_APP=$(echo "$LIST_BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    apps = d.get('applications', [])
    print(apps[0]['id'] if apps else '')
except Exception as e:
    print(f'  JSON parse error: {e}', file=sys.stderr)
    print('')
" 2>/dev/null)

if [ -n "$EXISTING_APP" ]; then
    APP_ID="$EXISTING_APP"
    echo "  App already exists: $APP_ID — deleting and recreating..."
    DEL_CODE=$(curl -s $CURL_SSL -o /dev/null -w "%{http_code}" -X DELETE \
        "${IS_BASE}/api/server/v1/applications/${APP_ID}" \
        -H "Authorization: Basic $ADMIN_CRED")
    echo "  Delete returned HTTP $DEL_CODE"
fi

# Build the app creation JSON payload using python3 for safe JSON construction
# (matches production pattern from TestData_Add_OAuth_Apps_Without_Consent.jmx)
APP_JSON=$(python3 -c "
import json, sys

adaptive_script = sys.argv[1]
app_name = sys.argv[2]
callback_url = sys.argv[3]
client_id = sys.argv[4]
client_secret = sys.argv[5]

payload = {
    'name': app_name,
    'description': 'Performance test app for adaptive script testing',
    'claimConfiguration': {
        'dialect': 'LOCAL',
        'requestedClaims': [],
        'subject': {
            'claim': {'uri': 'http://wso2.org/claims/username'},
            'includeUserDomain': False,
            'includeTenantDomain': False,
            'useMappedLocalSubject': False
        }
    },
    'inboundProtocolConfiguration': {
        'oidc': {
            'accessToken': {
                'type': 'Default',
                'userAccessTokenExpiryInSeconds': 3600,
                'applicationAccessTokenExpiryInSeconds': 3600,
                'bindingType': 'sso-session',
                'revokeTokensWhenIDPSessionTerminated': False,
                'validateTokenBinding': False
            },
            'allowedOrigins': [],
            'callbackURLs': [callback_url],
            'grantTypes': ['authorization_code'],
            'idToken': {
                'audience': [],
                'encryption': {
                    'algorithm': '',
                    'enabled': False,
                    'method': ''
                },
                'expiryInSeconds': 3600
            },
            'pkce': {
                'mandatory': False,
                'supportPlainTransformAlgorithm': True
            },
            'publicClient': False,
            'refreshToken': {
                'expiryInSeconds': 86400,
                'renewRefreshToken': True
            },
            'scopeValidators': [],
            'validateRequestObjectSignature': False,
            'clientId': client_id,
            'clientSecret': client_secret
        }
    },
    'advancedConfigurations': {
        'skipLoginConsent': True,
        'skipLogoutConsent': True,
        'enableAPIBasedAuthentication': True
    },
    'authenticationSequence': {
        'type': 'USER_DEFINED',
        'steps': [
            {
                'id': 1,
                'options': [{'idp': 'LOCAL', 'authenticator': 'BasicAuthenticator'}]
            },
            {
                'id': 2,
                'options': [{'idp': 'LOCAL', 'authenticator': 'totp'}]
            }
        ],
        'subjectStepId': 1,
        'attributeStepId': 1,
        'script': adaptive_script
    }
}

print(json.dumps(payload))
" "$ADAPTIVE_SCRIPT" "$APP_NAME" "$CALLBACK_URL" "$CLIENT_ID_VALUE" "$CLIENT_SECRET_VALUE")

if [ -z "$APP_JSON" ]; then
    echo "  ERROR: Failed to build app creation JSON payload"
    exit 1
fi

echo "  App creation payload built ($(echo "$APP_JSON" | wc -c | tr -d ' ') bytes)"

CREATE_RESP=$(curl -s $CURL_SSL -w "\n%{http_code}" -X POST "${IS_BASE}/api/server/v1/applications" \
    -H "Authorization: Basic $ADMIN_CRED" \
    -H "Content-Type: application/json" \
    -d "$APP_JSON")
CREATE_HTTP_CODE=$(echo "$CREATE_RESP" | tail -1)
CREATE_BODY=$(echo "$CREATE_RESP" | sed '$d')

if [ "$CREATE_HTTP_CODE" != "201" ] && [ "$CREATE_HTTP_CODE" != "200" ]; then
    echo "  ERROR: App creation returned HTTP $CREATE_HTTP_CODE"
    echo "  Response: $CREATE_BODY"
    exit 1
fi

APP_ID=$(echo "$CREATE_BODY" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('id',''))
except:
    print('')
")
echo "  App created: $APP_ID"

if [ -z "$APP_ID" ]; then
    echo "ERROR: Could not create application. Check API responses above."
    exit 1
fi

# Use the explicit client ID/secret we set (no need to query OIDC config)
CLIENT_ID="$CLIENT_ID_VALUE"
CLIENT_SECRET="$CLIENT_SECRET_VALUE"

echo "  Client ID: $CLIENT_ID"
echo "  Client Secret: $CLIENT_SECRET"
echo "  Auth sequence: USER_DEFINED (2-step adaptive script — configured inline)"

# Save credentials
echo "clientId,clientSecret,callbackUrl,appId" > "$CREDS_FILE"
echo "${CLIENT_ID},${CLIENT_SECRET},${CALLBACK_URL},${APP_ID}" >> "$CREDS_FILE"
echo "  Saved to $CREDS_FILE"

# ============================================================
# Step 3: Create Application Roles
# ============================================================
echo ""
echo "Step 3: Creating application roles ..."

ADMIN_ROLE_ID=""
MANAGER_ROLE_ID=""
EMPLOYEE_ROLE_ID=""

for role_name in admin manager employee; do
    # Check if role already exists
    ROLE_LIST_BODY=$(curl -s $CURL_SSL \
        "${IS_BASE}/scim2/v2/Roles?filter=displayName+eq+${role_name}+and+audience.value+eq+${APP_ID}" \
        -H "Authorization: Basic $ADMIN_CRED")

    EXISTING_ROLE=$(echo "$ROLE_LIST_BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    resources = d.get('Resources', [])
    for r in resources:
        aud = r.get('audience', {})
        if aud.get('value') == '$APP_ID':
            print(r['id'])
            break
except:
    pass
" 2>/dev/null)

    if [ -n "$EXISTING_ROLE" ]; then
        ROLE_ID="$EXISTING_ROLE"
        echo "  $role_name: exists ($ROLE_ID)"
    else
        ROLE_CREATE_RESP=$(curl -s $CURL_SSL -w "\n%{http_code}" -X POST "${IS_BASE}/scim2/v2/Roles" \
            -H "Authorization: Basic $ADMIN_CRED" \
            -H "Content-Type: application/json" \
            -d "{\"displayName\": \"$role_name\", \"audience\": {\"value\": \"$APP_ID\", \"type\": \"application\"}}")
        ROLE_CREATE_CODE=$(echo "$ROLE_CREATE_RESP" | tail -1)
        ROLE_CREATE_BODY=$(echo "$ROLE_CREATE_RESP" | sed '$d')

        if [ "$ROLE_CREATE_CODE" != "201" ] && [ "$ROLE_CREATE_CODE" != "200" ]; then
            echo "  WARNING: $role_name role creation returned HTTP $ROLE_CREATE_CODE"
            echo "  Response: $ROLE_CREATE_BODY"
        fi

        ROLE_ID=$(echo "$ROLE_CREATE_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")
        echo "  $role_name: created ($ROLE_ID)"
    fi

    case "$role_name" in
        admin)    ADMIN_ROLE_ID="$ROLE_ID" ;;
        manager)  MANAGER_ROLE_ID="$ROLE_ID" ;;
        employee) EMPLOYEE_ROLE_ID="$ROLE_ID" ;;
    esac
done

# ============================================================
# Step 4: Assign Existing Users to Employee Role
# ============================================================
echo ""
echo "Step 4: Assigning $USER_COUNT existing users to employee role ..."

# Build batch of user IDs for role assignment
# Process in batches of 50
BATCH_SIZE=50
ASSIGNED=0

for ((start=1; start<=USER_COUNT; start+=BATCH_SIZE)); do
    end=$((start + BATCH_SIZE - 1))
    if [ $end -gt $USER_COUNT ]; then
        end=$USER_COUNT
    fi

    # Build user value array for this batch
    USER_VALUES=""
    for ((i=start; i<=end; i++)); do
        USERNAME="${USERNAME_PREFIX}${i}"

        # Get user ID
        USER_ID=$(curl -s $CURL_SSL \
            "${IS_BASE}/scim2/Users?filter=userName+eq+${USERNAME}&attributes=id" \
            -H "Authorization: Basic $ADMIN_CRED" | \
            python3 -c "
import sys, json
try:
    u = json.load(sys.stdin).get('Resources', [])
    print(u[0]['id'] if u else '')
except:
    print('')
")

        if [ -n "$USER_ID" ]; then
            if [ -n "$USER_VALUES" ]; then
                USER_VALUES+=","
            fi
            USER_VALUES+="{\"value\": \"$USER_ID\"}"
            ASSIGNED=$((ASSIGNED + 1))
        fi
    done

    # Batch assign to employee role
    if [ -n "$USER_VALUES" ]; then
        ASSIGN_RESP=$(curl -s $CURL_SSL -w "\n%{http_code}" -X PATCH "${IS_BASE}/scim2/v2/Roles/$EMPLOYEE_ROLE_ID" \
            -H "Authorization: Basic $ADMIN_CRED" \
            -H "Content-Type: application/json" \
            -d "{\"Operations\": [{\"op\": \"add\", \"path\": \"users\", \"value\": [$USER_VALUES]}]}")
        ASSIGN_CODE=$(echo "$ASSIGN_RESP" | tail -1)
        if [ "$ASSIGN_CODE" != "200" ]; then
            ASSIGN_BODY=$(echo "$ASSIGN_RESP" | sed '$d')
            echo "  WARNING: Role assignment returned HTTP $ASSIGN_CODE for users $start-$end"
            echo "  Response: $(echo "$ASSIGN_BODY" | head -c 200)"
        fi
    fi

    echo "  Assigned users $start-$end ($ASSIGNED total so far)"
done

echo "  Total assigned: $ASSIGNED"

# ============================================================
# Step 5: Write CSV file (for existing users as employees)
# ============================================================
echo ""
echo "Step 5: Generating role_users.csv ..."

echo "username,password,totpSecret,role" > "$CSV_FILE"

# Add existing users as employees
for ((i=1; i<=USER_COUNT; i++)); do
    echo "${USERNAME_PREFIX}${i},${USER_PASSWORD},,employee" >> "$CSV_FILE"
done

# ============================================================
# Step 6: Create Dedicated Role Users (if requested)
# ============================================================
# Creates users and assigns them to application roles.
# No TOTP enrollment — just user creation + role assignment.
# TOTP can be added later when manager/admin path testing is needed.
if [ "$ADMIN_COUNT" -gt 0 ] || [ "$MANAGER_COUNT" -gt 0 ] || [ "$EMPLOYEE_COUNT" -gt 0 ]; then
    echo ""
    echo "Step 6: Creating dedicated role users (no TOTP) ..."

    ROLE_USER_PASSWORD="Test@1234!"

    # Helper: create users in batch and assign to role
    create_role_users_batch() {
        local prefix="$1"
        local count="$2"
        local role_name="$3"
        local role_id=""
        case "$role_name" in
            admin)    role_id="$ADMIN_ROLE_ID" ;;
            manager)  role_id="$MANAGER_ROLE_ID" ;;
            employee) role_id="$EMPLOYEE_ROLE_ID" ;;
        esac

        local created=0
        local batch_user_values=""
        local batch_count=0

        for ((i=1; i<=count; i++)); do
            local username="${prefix}${i}"

            # Create user via SCIM2
            local user_id=$(curl -s $CURL_SSL -X POST "${IS_BASE}/scim2/Users" \
                -H "Authorization: Basic $ADMIN_CRED" \
                -H "Content-Type: application/json" \
                -d "{\"schemas\":[\"urn:ietf:params:scim:schemas:core:2.0:User\"],\"userName\":\"$username\",\"password\":\"$ROLE_USER_PASSWORD\",\"name\":{\"givenName\":\"$role_name\",\"familyName\":\"User\"},\"emails\":[{\"primary\":true,\"value\":\"${username}@example.com\"}]}" | \
                python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('id',''))
except:
    print('')
")

            if [ -z "$user_id" ]; then
                echo "  WARNING: Failed to create $username (may already exist)"
                # Try to get existing user ID
                user_id=$(curl -s $CURL_SSL \
                    "${IS_BASE}/scim2/Users?filter=userName+eq+${username}&attributes=id" \
                    -H "Authorization: Basic $ADMIN_CRED" | \
                    python3 -c "
import sys, json
try:
    u = json.load(sys.stdin).get('Resources', [])
    print(u[0]['id'] if u else '')
except:
    print('')
")
            fi

            if [ -n "$user_id" ]; then
                if [ -n "$batch_user_values" ]; then
                    batch_user_values+=","
                fi
                batch_user_values+="{\"value\": \"$user_id\"}"
                batch_count=$((batch_count + 1))
                created=$((created + 1))

                # Write to CSV
                echo "${username},${ROLE_USER_PASSWORD},,${role_name}" >> "$CSV_FILE"
            fi

            # Batch assign roles every 50 users
            if [ "$batch_count" -ge 50 ] || [ "$i" -eq "$count" ]; then
                if [ -n "$batch_user_values" ]; then
                    local batch_assign_code=$(curl -s $CURL_SSL -o /dev/null -w "%{http_code}" -X PATCH "${IS_BASE}/scim2/v2/Roles/$role_id" \
                        -H "Authorization: Basic $ADMIN_CRED" \
                        -H "Content-Type: application/json" \
                        -d "{\"Operations\": [{\"op\": \"add\", \"path\": \"users\", \"value\": [$batch_user_values]}]}")
                    if [ "$batch_assign_code" != "200" ]; then
                        echo "  WARNING: $role_name batch assign returned HTTP $batch_assign_code"
                    fi
                    echo "  $role_name: assigned batch up to $i ($created created)"
                    batch_user_values=""
                    batch_count=0
                fi
            fi
        done

        echo "  $role_name: $created users created and assigned"
    }

    # Create admin users
    if [ "$ADMIN_COUNT" -gt 0 ]; then
        echo ""
        echo "--- Creating $ADMIN_COUNT admin users ---"
        create_role_users_batch "role_admin_" "$ADMIN_COUNT" "admin"
    fi

    # Create manager users
    if [ "$MANAGER_COUNT" -gt 0 ]; then
        echo ""
        echo "--- Creating $MANAGER_COUNT manager users ---"
        create_role_users_batch "role_manager_" "$MANAGER_COUNT" "manager"
    fi

    # Create dedicated employee users
    if [ "$EMPLOYEE_COUNT" -gt 0 ]; then
        echo ""
        echo "--- Creating $EMPLOYEE_COUNT dedicated employee users ---"
        create_role_users_batch "role_employee_" "$EMPLOYEE_COUNT" "employee"
    fi
fi

echo ""
echo "============================================================"
echo "  Setup Complete"
echo "  App: $APP_NAME (ID: $APP_ID)"
echo "  Client ID: $CLIENT_ID"
echo "  Roles: admin($ADMIN_ROLE_ID) manager($MANAGER_ROLE_ID) employee($EMPLOYEE_ROLE_ID)"
echo "  Employees assigned: $ASSIGNED existing + $EMPLOYEE_COUNT dedicated"
echo "  Admins: $ADMIN_COUNT, Managers: $MANAGER_COUNT"
echo "  Credentials: $CREDS_FILE"
echo "  CSV: $CSV_FILE ($(wc -l < "$CSV_FILE") lines)"
echo "============================================================"
