#!/usr/bin/env python3
"""
Reset default pack (9444): deploy clean script, fix consent, delete+recreate users.
"""
import requests, json, time, concurrent.futures
from urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

BASE = "https://localhost:9444"
AUTH = ("admin", "admin")
VERIFY = False
PASSWORD = "Test@1234!"
TOTAL_USERS = 1000
BATCH_SIZE = 10
MAX_RETRIES = 3
APP_ID = "f58d6e6b-ec3d-4131-b20e-0899a9fb2714"

CLEAN_SCRIPT = """var rolesToStepUp = ['admin', 'manager'];

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
                    onSuccess: function(context) { Log.info('[TEST] STEP 2 SUCCESS'); },
                    onFail: function(context) { Log.info('[TEST] STEP 2 FAILED'); }
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


def delete_user(uid):
    for _ in range(MAX_RETRIES):
        try:
            r = requests.delete(f"{BASE}/scim2/Users/{uid}", auth=AUTH, verify=VERIFY, timeout=15)
            if r.status_code in [204, 404]: return True
        except: time.sleep(0.5)
    return False

def create_user(username):
    payload = {"schemas":["urn:ietf:params:scim:schemas:core:2.0:User"],"userName":username,"password":PASSWORD,"name":{"givenName":username,"familyName":"TestUser"}}
    for _ in range(MAX_RETRIES):
        try:
            r = requests.post(f"{BASE}/scim2/Users", json=payload, auth=AUTH, verify=VERIFY, timeout=15, headers={"Content-Type":"application/json"})
            if r.status_code in [201, 409]: return True
        except: time.sleep(0.5)
    return False

def get_all_user_ids():
    ids = []
    start = 1
    while True:
        r = requests.get(f"{BASE}/scim2/Users", params={"filter":"userName sw role_employee","count":100,"startIndex":start,"attributes":"id,userName"}, auth=AUTH, verify=VERIFY, timeout=30)
        if r.status_code != 200: break
        res = r.json().get("Resources",[])
        if not res: break
        for u in res: ids.append((u["id"], u["userName"]))
        if start + 100 > r.json().get("totalResults",0): break
        start += 100
    return ids

def main():
    print("=" * 60)
    print("RESET DEFAULT PACK (9444)")
    print("=" * 60)

    # 1. Deploy clean adaptive script
    print("\n[1/4] Deploying clean adaptive script...")
    app = requests.get(f"{BASE}/api/server/v1/applications/{APP_ID}", auth=AUTH, verify=VERIFY).json()
    steps = app.get("authenticationSequence",{}).get("steps",[])
    r = requests.patch(f"{BASE}/api/server/v1/applications/{APP_ID}",
        json={"authenticationSequence":{"type":"USER_DEFINED","steps":steps,"script":CLEAN_SCRIPT}},
        auth=AUTH, verify=VERIFY, headers={"Content-Type":"application/json"})
    if r.status_code == 200:
        v = requests.get(f"{BASE}/api/server/v1/applications/{APP_ID}", auth=AUTH, verify=VERIFY).json()
        s = v.get("authenticationSequence",{}).get("script","")
        if "httpGet" not in s and "updateUserPassword" not in s:
            print("  ✅ Clean script deployed")
        else:
            print("  ⚠️  Script still has problematic functions")
    else:
        print(f"  ❌ PATCH failed: {r.status_code}")

    # 2. Fix consent
    print("\n[2/4] Fixing skipLoginConsent...")
    r = requests.patch(f"{BASE}/api/server/v1/applications/{APP_ID}",
        json={"advancedConfigurations":{"skipLoginConsent":True,"skipLogoutConsent":True}},
        auth=AUTH, verify=VERIFY, headers={"Content-Type":"application/json"})
    print(f"  {'✅' if r.status_code==200 else '❌'} skipLoginConsent={r.status_code==200}")

    # 3. Delete all users
    print("\n[3/4] Deleting all users...")
    while True:
        users = get_all_user_ids()
        if not users:
            print("  All users deleted!")
            break
        print(f"  {len(users)} users remaining...")
        d, f = 0, 0
        for i in range(0, len(users), BATCH_SIZE):
            batch = users[i:i+BATCH_SIZE]
            with concurrent.futures.ThreadPoolExecutor(max_workers=BATCH_SIZE) as ex:
                results = list(ex.map(lambda u: delete_user(u[0]), batch))
            d += sum(1 for r in results if r)
            f += sum(1 for r in results if not r)
            print(f"    {min(i+BATCH_SIZE,len(users))}/{len(users)} (del={d} fail={f})", end="\r")
        print(f"\n    Round: deleted={d}, failed={f}")
        if f == len(users): break
        time.sleep(2)

    # 4. Create all users
    print(f"\n[4/4] Creating {TOTAL_USERS} users...")
    c, f = 0, 0
    for i in range(0, TOTAL_USERS, BATCH_SIZE):
        batch = [f"role_employee_{j}" for j in range(i+1, min(i+BATCH_SIZE+1, TOTAL_USERS+1))]
        with concurrent.futures.ThreadPoolExecutor(max_workers=BATCH_SIZE) as ex:
            results = list(ex.map(create_user, batch))
        c += sum(1 for r in results if r)
        f += sum(1 for r in results if not r)
        print(f"  {min(i+BATCH_SIZE,TOTAL_USERS)}/{TOTAL_USERS} (created={c} failed={f})", end="\r")
    print(f"\n  ✅ Created: {c}, Failed: {f}")

    # Verify
    r = requests.get(f"{BASE}/scim2/Users", params={"filter":"userName sw role_employee","count":1}, auth=AUTH, verify=VERIFY)
    print(f"\n  Final user count: {r.json().get('totalResults',0)}")

    # Login test
    print("  Testing login...")
    s = requests.Session(); s.verify = False
    r1 = s.get(f"{BASE}/oauth2/authorize", params={"response_type":"code","client_id":"plAJCI5t9D6DSg24bsGMQztVT6sa","redirect_uri":"https://localhost/callback","scope":"openid"}, allow_redirects=False)
    loc = r1.headers.get("Location","")
    if "sessionDataKey=" in loc:
        sdk = loc.split("sessionDataKey=")[1].split("&")[0]
        r2 = s.post(f"{BASE}/commonauth", data={"sessionDataKey":sdk,"username":"role_employee_1","password":PASSWORD}, allow_redirects=False)
        if "commonAuthId" in dict(r2.cookies):
            print("  ✅ Login PASSED - commonAuthId cookie SET")
        else:
            print(f"  ⚠️  Cookies: {list(dict(r2.cookies).keys())}")
    else:
        print("  ⚠️  Could not get sessionDataKey")

    print("\n" + "=" * 60)
    print("DONE - Ready for JMeter test")
    print("=" * 60)

if __name__ == "__main__":
    main()
