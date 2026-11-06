#!/usr/bin/env python3
"""Carry frozen builder code AND the matching review reply transcripts into a new run root (L2).

Usage: carry_builds.py SRC_ROOT DST_ROOT --ra SEND_ID --rb SEND_ID
Copies:
  builds/frozen/<id>/...
  analysis/r_a/main.R, analysis/r_b/main.R (from frozen)
  transcripts/execution/<id>_reply.md
Records provenance at artifacts/carried_builds.json (write-once).
"""
import argparse, os, sys, json, hashlib, shutil, datetime
ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("dst")
ap.add_argument("--ra", required=True); ap.add_argument("--rb", required=True)
a = ap.parse_args()
sha = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
def copy_file(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst): sys.exit(f"FAIL exists {dst}")
    shutil.copy2(src, dst); os.chmod(dst, 0o444)
    return {"path": os.path.relpath(dst, a.dst), "sha256": sha(dst), "from": os.path.relpath(src, a.src)}
entries = []
mapping = [("R-A", a.ra, "r_a"), ("R-B", a.rb, "r_b")]
for role, sid, sub in mapping:
    fr = os.path.join(a.src, "builds", "frozen", sid, "analysis", sub, "main.R")
    tr = os.path.join(a.src, "transcripts", "execution", f"{sid}_reply.md")
    if not os.path.isfile(fr): sys.exit(f"FAIL missing frozen builder {fr}")
    if not os.path.isfile(tr): sys.exit(f"FAIL missing transcript {tr} (L2: carry replies with code)")
    entries.append({"role": role, "send_id": sid, "frozen": copy_file(fr, os.path.join(a.dst, "builds", "frozen", sid, "analysis", sub, "main.R"))})
    entries[-1]["transcript"] = copy_file(tr, os.path.join(a.dst, "transcripts", "execution", f"{sid}_reply.md"))
    entries[-1]["installed"] = copy_file(fr, os.path.join(a.dst, "analysis", sub, "main.R"))
prov = {
    "carried_at_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "source_root_note": "byte carry of frozen builders + reply transcripts (L2)",
    "entries": entries,
}
out = os.path.join(a.dst, "artifacts", "carried_builds.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
if os.path.exists(out): sys.exit("FAIL carried_builds.json exists")
open(out, "w").write(json.dumps(prov, indent=1) + "\n"); os.chmod(out, 0o444)
print("carried", len(entries), "builders+transcripts")
