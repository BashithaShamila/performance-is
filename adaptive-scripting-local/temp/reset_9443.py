#!/usr/bin/env python3
"""
Reset script for updated pack (9443):
1. Delete all 1000 role_employee users
2. Recreate them with correct password (Test@1234!)
3. Deploy clean adaptive script to AdaptiveScriptJMeterTest app
"""

import requests
import json
import time
import sys
import concurrent.futures
from urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

BASE = "https://localhost:9443"
AUTH = ("admin", "admin")
VERIFY = False
PASSWORD = "Test@1234!"
TOTAL_USERS = 1000
BATCH_SIZE = 50  # parallel requests per batch

# Clean adaptive script (simple role-based, no extra host functions)
CLEAN_ADAPTIVE_SCRIPT = """var rolesToStepUp = ['admin', 'manager'];

var onLoginRequest = function(context) {
    executeStep(1, {
        onSuccess: function(context) {
            var hasAdminOrManager = false;
            try {
                hasAdminOrManager = hasAnyOfTheRolesV2(context, rolesToStepUp);
            } catch(e) {
                Log.info('[TEST] Step 2 Role Check ERROR: ' + e.message);
            }

            if (hasAdminOrManager) {
                Log.info('[TEST] Admin/Manager detected. Triggering Step 2.');

                executeStep(2, {
                    onSuccess: function(context) {
                        Log.info('[TEST] STEP 2 SUCCESS');
                    },
                    onFail: function(context) {
                        Log.info('[TEST] STEP 2 FAILED');
                    }
                });
            } else {
                Log.info('[TEST] Step 2 Skipped (Employee - no TOTP needed)');
            }
        },
        onFail: function(context) {
            Log.info('[TEST] STEP 1 FAILED - Invalid Credentials');
        }
    });
};"""


def get_all_user_ids():
    """Fetch all role_employee user IDs using pagination."""
    user_ids = []
    start = 1
    count = 100

    while True:
        resp = requests.get(
            f"{BASE}/scim2/Users",
            params={
                "filter": "userName sw role_employee",
                "count": count,
                "startIndex": start,
                "attributes": "id,userName"
            },
            auth=AUTH, verify=VERIFY
        )

        if resp.status_code != 200:
            print(f"  ERROR fetching users at startIndex={start}: {resp.status_code}")
            break

        data = resp.json()
        resources = data.get("Resources", [])
        if not resources:
            break

        for r in resources:
            user_ids.append((r["id"], r["userName"]))

        total = data.get("totalResults", 0)
        start += count
        if start > total:
            break

    return user_ids


def delete_user(user_id_name):
    """Delete a single user by ID."""
    uid, uname = user_id_name
    try:
        resp = requests.delete(
            f"{BASE}/scim2/Users/{uid}",
            auth=AUTH, verify=VERIFY, timeout=10
        )
        return (uname, resp.status_code == 204)
    except Exception as e:
        return (uname, False)


def create_user(username):
    """Create a single user with the correct password."""
    payload = {
        "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "userName": username,
        "password": PASSWORD,
        "name": {
            "givenName": username,
            "familyName": "TestUser"
        }
    }
    try:
        resp = requests.post(
            f"{BASE}/scim2/Users",
            json=payload,
            auth=AUTH, verify=VERIFY, timeout=10,
            headers={"Content-Type": "application/json"}
        )
        return (username, resp.status_code == 201)
    except Exception as e:
        return (username, False)


def deploy_adaptive_script():
    """Deploy clean adaptive script to the app."""
    # Get app ID
    resp = requests.get(
        f"{BASE}/api/server/v1/applications",
        params={"filter": "name eq AdaptiveScriptJMeterTest"},
        auth=AUTH, verify=VERIFY
    )

    if resp.status_code != 200:
        print(f"ERROR: Could not list applications: {resp.status_code}")
        return False

    apps = resp.json().get("applications", [])
    if not apps:
        print("ERROR: AdaptiveScriptJMeterTest app not found!")
        return False

    app_id = apps[0]["id"]
    print(f"  App ID: {app_id}")

    # Get current app config
    resp = requests.get(
        f"{BASE}/api/server/v1/applications/{app_id}",
        auth=AUTH, verify=VERIFY
    )
    app_data = resp.json()
    auth_seq = app_data.get("authenticationSequence", {})

    # Update with clean script
    patch_payload = {
        "authenticationSequence": {
            "type": "USER_DEFINED",
            "steps": auth_seq.get("steps", []),
            "script": CLEAN_ADAPTIVE_SCRIPT
        }
    }

    resp = requests.patch(
        f"{BASE}/api/server/v1/applications/{app_id}",
        json=patch_payload,
        auth=AUTH, verify=VERIFY,
        headers={"Content-Type": "application/json"}
    )

    if resp.status_code == 200:
        # Verify
        resp2 = requests.get(
            f"{BASE}/api/server/v1/applications/{app_id}",
            auth=AUTH, verify=VERIFY
        )
        deployed_script = resp2.json().get("authenticationSequence", {}).get("script", "")
        if "httpGet" not in deployed_script and "updateUserPassword" not in deployed_script:
            return True
        else:
            print("WARNING: Script still contains problematic functions!")
            return False
    else:
        print(f"ERROR: PATCH failed with {resp.status_code}: {resp.text[:200]}")
        return False


def main():
    print("=" * 60)
    print("RESET UPDATED PACK (9443) - FRESH START")
    print("=" * 60)

    # ---- STEP 1: Deploy clean adaptive script ----
    print("\n[1/3] Deploying clean adaptive script...")
    if deploy_adaptive_script():
        print("  ✅ Clean adaptive script deployed (no httpGet/updateUserPassword)")
    else:
        print("  ❌ Failed to deploy script. Continuing with user reset...")

    # ---- STEP 2: Delete all users ----
    print("\n[2/3] Deleting all role_employee users...")
    user_ids = get_all_user_ids()
    print(f"  Found {len(user_ids)} users to delete")

    deleted = 0
    failed_delete = 0

    for i in range(0, len(user_ids), BATCH_SIZE):
        batch = user_ids[i:i + BATCH_SIZE]
        with concurrent.futures.ThreadPoolExecutor(max_workers=BATCH_SIZE) as executor:
            results = list(executor.map(delete_user, batch))

        for uname, success in results:
            if success:
                deleted += 1
            else:
                failed_delete += 1

        progress = min(i + BATCH_SIZE, len(user_ids))
        print(f"  Progress: {progress}/{len(user_ids)} (deleted={deleted}, failed={failed_delete})", end="\r")

    print(f"\n  ✅ Deleted: {deleted}, Failed: {failed_delete}")

    # Brief pause to let the server settle
    print("  Waiting 3s for server to settle...")
    time.sleep(3)

    # ---- STEP 3: Recreate all users ----
    print(f"\n[3/3] Creating {TOTAL_USERS} users with password '{PASSWORD}'...")

    usernames = [f"role_employee_{i}" for i in range(1, TOTAL_USERS + 1)]
    created = 0
    failed_create = 0

    for i in range(0, len(usernames), BATCH_SIZE):
        batch = usernames[i:i + BATCH_SIZE]
        with concurrent.futures.ThreadPoolExecutor(max_workers=BATCH_SIZE) as executor:
            results = list(executor.map(create_user, batch))

        for uname, success in results:
            if success:
                created += 1
            else:
                failed_create += 1

        progress = min(i + BATCH_SIZE, len(usernames))
        print(f"  Progress: {progress}/{TOTAL_USERS} (created={created}, failed={failed_create})", end="\r")

    print(f"\n  ✅ Created: {created}, Failed: {failed_create}")

    # ---- VERIFICATION ----
    print("\n" + "=" * 60)
    print("VERIFICATION")
    print("=" * 60)

    # Check user count
    resp = requests.get(
        f"{BASE}/scim2/Users",
        params={"filter": "userName sw role_employee", "count": 1},
        auth=AUTH, verify=VERIFY
    )
    total_now = resp.json().get("totalResults", 0)
    print(f"  Users in system: {total_now}")

    # Test login with first user
    print("  Testing login with role_employee_1...")
    login_resp = requests.post(
        f"{BASE}/oauth2/authorize",
        params={
            "response_type": "code",
            "client_id": "HqfysAhVLVIE4TfX5pAOMGTXAaUa",
            "redirect_uri": "https://localhost/callback",
            "scope": "openid"
        },
        allow_redirects=False,
        auth=AUTH, verify=VERIFY
    )

    # Quick auth test via commonauth
    session = requests.Session()
    session.verify = False

    # Step 1: Get sessionDataKey
    r1 = session.get(
        f"{BASE}/oauth2/authorize",
        params={
            "response_type": "code",
            "client_id": "HqfysAhVLVIE4TfX5pAOMGTXAaUa",
            "redirect_uri": "https://localhost/callback",
            "scope": "openid"
        },
        allow_redirects=False
    )

    location = r1.headers.get("Location", "")
    if "sessionDataKey=" in location:
        sdk = location.split("sessionDataKey=")[1].split("&")[0]

        # Step 2: POST commonauth
        r2 = session.post(
            f"{BASE}/commonauth",
            data={
                "sessionDataKey": sdk,
                "username": "role_employee_1",
                "password": PASSWORD
            },
            allow_redirects=False
        )

        if r2.status_code in [302, 200]:
            loc2 = r2.headers.get("Location", "")
            cookies_set = dict(r2.cookies)
            if "commonAuthId" in cookies_set:
                print(f"  ✅ Login test PASSED - commonAuthId cookie SET!")
            elif "sessionDataKeyConsent" in loc2 or "code=" in loc2:
                print(f"  ✅ Login test PASSED - redirected to consent/code")
            else:
                print(f"  ⚠️  Login returned {r2.status_code}, Location: {loc2[:100]}")
                print(f"     Cookies: {list(cookies_set.keys())}")
        else:
            print(f"  ❌ Login FAILED with status {r2.status_code}")
    else:
        print(f"  ⚠️  Could not extract sessionDataKey from authorize response")

    print("\n" + "=" * 60)
    print("RESET COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
