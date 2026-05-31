#!/usr/bin/env python3
"""Audit airaMD auth: map auth.users <-> staff <-> clinic + roles.

Usage:  SVC=<service_role_key> python3 scripts/auth_audit.py
Read-only. Optionally reset a password:
        SVC=<key> python3 scripts/auth_audit.py reset <email> <new_password>
Test a login (uses anon key, no SVC needed):
        python3 scripts/auth_audit.py test <email> <password>
"""
import json
import os
import sys
import urllib.request

B = "https://pzqjqqaekxmfdlrxbgmk.supabase.co"
ANON = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6cWpxcWFla3htZmRscnhiZ21rIiwicm9sZSI6"
    "ImFub24iLCJpYXQiOjE3NzQyOTUzNTAsImV4cCI6MjA4OTg3MTM1MH0."
    "-1GEjKobBky0psImnCkhBZcaFzO3RQZ4gDyQV0MOUeM"
)


def _svc_headers():
    k = os.environ.get("SVC")
    if not k:
        sys.exit("SVC env var (service_role key) is required for this command")
    return {"apikey": k, "Authorization": f"Bearer {k}", "Content-Type": "application/json"}


H = None


def req(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(B + path, data=data, headers=H, method=method)
    with urllib.request.urlopen(r) as resp:
        raw = resp.read().decode()
        return json.loads(raw) if raw.strip() else None


def test_login(email, pw):
    headers = {"apikey": ANON, "Content-Type": "application/json"}
    url = B + "/auth/v1/token?grant_type=password"
    body = json.dumps({"email": email, "password": pw}).encode()
    r = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        d = json.loads(urllib.request.urlopen(r).read().decode())
        print(f"LOGIN OK   {email}  (token len {len(d.get('access_token',''))})")
    except urllib.error.HTTPError as e:
        print(f"LOGIN FAIL {email}  {e.code}  {e.read().decode()[:120]}")


def list_users():
    u = req("GET", "/auth/v1/admin/users?per_page=200")
    return u["users"] if isinstance(u, dict) else u


def _count(table, clinic_id):
    # HEAD request with count header
    url = B + f"/rest/v1/{table}?clinic_id=eq.{clinic_id}&select=id"
    r = urllib.request.Request(url, headers={**H, "Prefer": "count=exact",
                                             "Range-Unit": "items", "Range": "0-0"})
    try:
        with urllib.request.urlopen(r) as resp:
            cr = resp.headers.get("Content-Range", "*/0")
            return int(cr.split("/")[-1]) if "/" in cr else 0
    except urllib.error.HTTPError:
        return -1


def counts():
    clinics = req("GET", "/rest/v1/clinics?select=id,name")
    tables = ["patients", "products", "services", "appointments", "treatments",
              "courses", "financial_transactions", "staff"]
    for c in clinics:
        print(f"\nCLINIC: {c['name']}  ({c['id'][:8]})")
        for t in tables:
            print(f"  {t:24} {_count(t, c['id'])}")


def audit():
    users = list_users()
    um = {x["id"]: x.get("email") for x in users}
    staff = req("GET", "/rest/v1/staff?select=full_name,role,clinic_id,user_id,is_active")
    clinics = req("GET", "/rest/v1/clinics?select=id,name")
    cm = {c["id"]: c["name"] for c in clinics}

    print(f"=== STAFF ({len(staff)}) ===")
    print(f"{'EMAIL':32} {'ROLE':12} {'STAFF':20} {'ACTIVE':7} CLINIC")
    for x in staff:
        print(f"{um.get(x['user_id'],'(no-auth)'):32} {x['role']:12} "
              f"{x['full_name']:20} {str(x['is_active']):7} {cm.get(x['clinic_id'],'?')}")

    sids = {x["user_id"] for x in staff}
    orphan = [x for x in users if x["id"] not in sids]
    print(f"\n=== AUTH USERS WITHOUT STAFF ROW ({len(orphan)}) ===")
    for x in orphan:
        print(f"  {x.get('email'):32} confirmed={bool(x.get('email_confirmed_at'))}")


def purge(keep_email):
    """Delete every account/clinic except the one owned by keep_email.

    Relies on FK ON DELETE CASCADE (migration 001) — deleting a clinic
    row removes all of its child data automatically.
    """
    users = list_users()
    keep_user = next((x for x in users if x.get("email") == keep_email), None)
    if not keep_user:
        sys.exit(f"keep email {keep_email} not found in auth.users")
    keep_uid = keep_user["id"]

    staff = req("GET", "/rest/v1/staff?select=id,full_name,clinic_id,user_id")
    keep_staff = next((s for s in staff if s["user_id"] == keep_uid), None)
    if not keep_staff:
        sys.exit(f"no staff row for {keep_email}")
    keep_clinic = keep_staff["clinic_id"]
    print(f"KEEP  email={keep_email}  staff={keep_staff['full_name']}  clinic={keep_clinic[:8]}")

    clinics = req("GET", "/rest/v1/clinics?select=id,name")
    del_clinics = [c for c in clinics if c["id"] != keep_clinic]

    # 1. delete other clinics (cascades all their child data + staff rows)
    for c in del_clinics:
        req("DELETE", f"/rest/v1/clinics?id=eq.{c['id']}")
        print(f"  deleted clinic {c['name']} ({c['id'][:8]}) + cascaded data")

    # 2. delete extra staff rows left in the kept clinic (other owners)
    staff = req("GET", "/rest/v1/staff?select=id,full_name,user_id")
    for s in staff:
        if s["user_id"] != keep_uid:
            req("DELETE", f"/rest/v1/staff?id=eq.{s['id']}")
            print(f"  deleted extra staff row {s['full_name']} ({s['id'][:8]})")

    # 3. delete every auth user except the kept one
    for u in users:
        if u["id"] != keep_uid:
            req("DELETE", f"/auth/v1/admin/users/{u['id']}")
            print(f"  deleted auth user {u.get('email')}")

    print("\n--- post-purge state ---")
    audit()


def reset(email, pw):
    users = list_users()
    match = [x for x in users if x.get("email") == email]
    if not match:
        sys.exit(f"no auth user with email {email}")
    uid = match[0]["id"]
    d = req("PUT", f"/auth/v1/admin/users/{uid}",
            {"password": pw, "email_confirm": True})
    print(f"password reset OK for {d.get('email')} (id {uid[:8]})")


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "test":
        test_login(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 4 and sys.argv[1] == "reset":
        H = _svc_headers()
        reset(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 2 and sys.argv[1] == "counts":
        H = _svc_headers()
        counts()
    elif len(sys.argv) >= 3 and sys.argv[1] == "purge":
        H = _svc_headers()
        purge(sys.argv[2])
    else:
        H = _svc_headers()
        audit()
