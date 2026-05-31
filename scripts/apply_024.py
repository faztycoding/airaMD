#!/usr/bin/env python3
"""Idempotently apply migration 024 (Harmonica + Juvelook) to prod via REST.

Usage:  SVC=<service_role_key> python3 scripts/apply_024.py

Reads the service-role key from the SVC env var (never hard-coded here).
Safe to re-run: only inserts a (clinic_id, name) pair that is absent.
"""
import json
import os
import sys
import urllib.request

KEY = os.environ.get("SVC")
if not KEY:
    sys.exit("SVC env var (service_role key) is required")

BASE = "https://pzqjqqaekxmfdlrxbgmk.supabase.co/rest/v1"
HEADERS = {
    "apikey": KEY,
    "Authorization": f"Bearer {KEY}",
    "Content-Type": "application/json",
}

MEDS = [
    {"name": "Harmonica", "brand": "Allergan", "category": "BIOSTIMULATOR",
     "unit": "syringe", "default_price": 17000},
    {"name": "Juvelook", "brand": "Vaim", "category": "BIOSTIMULATOR",
     "unit": "vial", "default_price": 10000},
]


def req(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(BASE + path, data=data, headers=HEADERS, method=method)
    with urllib.request.urlopen(r) as resp:
        raw = resp.read().decode()
        return resp.status, (json.loads(raw) if raw.strip() else None)


def main():
    # 1. clinics
    _, clinics = req("GET", "/clinics?select=id,name")
    print(f"clinics: {len(clinics)}")

    # 2. existing harmonica/juvelook
    _, existing = req(
        "GET",
        "/products?select=clinic_id,name&or=(name.ilike.*harmonica*,name.ilike.*juvelook*)",
    )
    have = {(e["clinic_id"], e["name"].lower()) for e in existing}
    print(f"already present: {len(have)}")

    # 3. build missing rows
    rows = []
    for c in clinics:
        for m in MEDS:
            if (c["id"], m["name"].lower()) not in have:
                rows.append({**m, "clinic_id": c["id"], "stock_quantity": 0, "is_active": True})

    if not rows:
        print("nothing to insert — already complete")
    else:
        print(f"inserting {len(rows)} rows...")
        status, _ = req("POST", "/products", rows)
        print(f"POST status: {status}")

    # 4. verify
    _, after = req(
        "GET",
        "/products?select=clinic_id,name,category,unit,default_price&or=(name.ilike.*harmonica*,name.ilike.*juvelook*)&order=name,clinic_id",
    )
    print(f"\nVERIFY — {len(after)} rows:")
    for a in after:
        print(f"  {a['name']:10} {a['unit']:8} {a['default_price']:>9} {a['clinic_id']}")


if __name__ == "__main__":
    main()
