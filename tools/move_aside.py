#!/usr/bin/env python3
"""Move write-once outputs aside into a numbered attempt directory. Never deletes.

L4 (STAGE4_RISK_AUDIT): compose/verify leave partial receipts that block reruns.
Usage: move_aside.py ROOT REL_PATH [REL_PATH ...]
  Each existing REL_PATH is renamed to outputs/superseded/attempt_<UTC>/<rel>.
Exit 0 if all moved or were absent; exit 1 on error.
"""
import os, sys, datetime, shutil
if len(sys.argv) < 3:
    sys.exit("Usage: move_aside.py ROOT REL_PATH [REL_PATH ...]\n       move_aside.py ROOT --verification-tree")
root = os.path.abspath(sys.argv[1])
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
base = os.path.join(root, "outputs", "superseded", f"attempt_{stamp}")
moved = []
rels = sys.argv[2:]
if rels == ['--verification-tree']:
    rels = ['outputs/verification', 'outputs/r_a', 'outputs/r_b']
for rel in rels:
    src = os.path.join(root, rel)
    if not os.path.exists(src):
        print(f"absent {rel}")
        continue
    dst = os.path.join(base, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst):
        sys.exit(f"FAIL destination exists: {dst}")
    os.rename(src, dst)
    moved.append((rel, os.path.relpath(dst, root)))
    print(f"moved {rel} -> {os.path.relpath(dst, root)}")
manifest = os.path.join(base, "MOVE_ASIDE.json")
os.makedirs(base, exist_ok=True)
import json
open(manifest, "w").write(json.dumps({
    "moved_at_utc": stamp + "Z" if not stamp.endswith("Z") else stamp,
    "moved": [{"from": a, "to": b} for a, b in moved],
}, indent=1) + "\n")
print("manifest", os.path.relpath(manifest, root))
