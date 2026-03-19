#!/usr/bin/env python3
"""
Reset script v2 - sequential with small batches to avoid overloading IS.
1. Delete all existing role_employee users
2. Recreate them with correct password (Test@1234!)
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
BATCH_SIZE = 10  # small batches to avoid overwhelming IS
MAX_RETRIES = 3


def delete_user(uid):
    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.delete(f"{BASE}/scim2/Users/{uid}", auth=AUTH, verify=VERIFY, timeout=15)
            if resp.status_code == 204:
                return True
            if resp.status_code == 404:
                return True  # already gone
        except:
            time.sleep(0.5)
    return False


def create_user(username):
    payload = {
        "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "userName": username,
        "password": PASSWORD,
        "name": {"givenName": username, "familyName": "TestUser"}
    }
    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.post(
                f"{BASE}/scim2/Users", json=payload,
                auth=AUTH, verify=VERIFY, timeout=15,
                headers={"Content-Type": "application/json"}
            )
            if resp.status_code == 201:
                return True
            if resp.status_code == 409:
                return True  # already exists
        except:
            time.sleep(0.5)
    return False


def get_all_user_ids():
    user_ids = []
    start = 1
    while True:
        resp = requests.get(
            f"{BASE}/scim2/Users",
            params={"filter": "userName sw role_employee", "count": 100, "startIndex": start, "attributes": "id,userName"},
            auth=AUTH, verify=VERIFY, timeout=30
        )
        if resp.status_code != 200:
            break
        data = resp.json()
        resources = data.get("Resources", [])
        if not resources:
            break
        for r in resources:
            user_ids.append((r["id"], r["userName"]))
        total = data.get("totalResults", 0)
        start += 100
        if start > total:
            break
    return user_ids


def main():
    print("=" * 60)
    print("PHASE 1: DELETE ALL EXISTING USERS")
    print("=" * 60)

    iteration = 0
    while True:
        iteration += 1
        users = get_all_user_ids()
        if not users:
            print(f"\n  All users deleted!")
            break

        print(f"\n  Iteration {iteration}: {len(users)} users remaining")

        deleted = 0
        failed = 0
        for i in range(0, len(users), BATCH_SIZE):
            batch = users[i:i + BATCH_SIZE]
            with concurrent.futures.ThreadPoolExecutor(max_workers=BATCH_SIZE) as ex:
                results = list(ex.map(lambda u: delete_user(u[0]), batch))
            deleted += sum(1 for r in results if r)
            failed += sum(1 for r in results if not r)
            done = min(i + BATCH_SIZE, len(users))
            print(f"    {done}/{len(users)} processed (del={deleted}, fail={failed})", end="\r")

        print(f"\n    Round result: deleted={deleted}, failed={failed}")

        if failed == len(users):
            print("  ERROR: All deletes failing, stopping.")
            break

        time.sleep(2)

    # Verify clean
    check = get_all_user_ids()
    print(f"\n  Users remaining after delete: {len(check)}")

    print("\n" + "=" * 60)
    print("PHASE 2: CREATE ALL 1000 USERS")
    print("=" * 60)

    usernames = [f"role_employee_{i}" for i in range(1, TOTAL_USERS + 1)]
    created = 0
    failed = 0

    for i in range(0, len(usernames), BATCH_SIZE):
        batch = usernames[i:i + BATCH_SIZE]
        with concurrent.futures.ThreadPoolExecutor(max_workers=BATCH_SIZE) as ex:
            results = list(ex.map(create_user, batch))
        created += sum(1 for r in results if r)
        failed += sum(1 for r in results if not r)
        done = min(i + BATCH_SIZE, len(usernames))
        print(f"  {done}/{TOTAL_USERS} (created={created}, failed={failed})", end="\r")

    print(f"\n  ✅ Created: {created}, Failed: {failed}")

    # Final count
    resp = requests.get(
        f"{BASE}/scim2/Users",
        params={"filter": "userName sw role_employee", "count": 1},
        auth=AUTH, verify=VERIFY
    )
    total_now = resp.json().get("totalResults", 0)
    print(f"\n  Final user count: {total_now}")

    # Quick login test
    print("\n  Testing login with role_employee_1...")
    session = requests.Session()
    session.verify = False
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
        r2 = session.post(
            f"{BASE}/commonauth",
            data={"sessionDataKey": sdk, "username": "role_employee_1", "password": PASSWORD},
            allow_redirects=False
        )
        cookies = dict(r2.cookies)
        if "commonAuthId" in cookies:
            print(f"  ✅ Login PASSED - commonAuthId cookie SET")
        else:
            print(f"  ⚠️  No commonAuthId - cookies: {list(cookies.keys())}")
            print(f"     Location: {r2.headers.get('Location', 'N/A')[:120]}")
    else:
        print(f"  ⚠️  Could not get sessionDataKey")

    print("\n" + "=" * 60)
    print("DONE")
    print("=" * 60)


if __name__ == "__main__":
    main()
