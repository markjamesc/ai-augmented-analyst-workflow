#!/usr/bin/env python3
"""Stage a writable root for planted-defect confirmation from an ACC004S-like template."""
import os, sys, shutil, subprocess
if len(sys.argv) < 4:
    sys.exit("Usage: stage_planted_root.py TEMPLATE DST GATE_REPO [RA_MAIN RB_MAIN]")
tmpl, dst, gate = sys.argv[1:4]
ra = sys.argv[4] if len(sys.argv) > 4 else None
rb = sys.argv[5] if len(sys.argv) > 5 else None
RS = os.environ.get("RSCRIPT", "/opt/mamba/envs/r/bin/Rscript")
if os.path.exists(dst): shutil.rmtree(dst)
os.makedirs(dst)
for sub in ("data", "validation", "artifacts", "environment", "analysis", "docs", "fixtures"):
    src = os.path.join(tmpl, sub)
    if os.path.isdir(src): shutil.copytree(src, os.path.join(dst, sub))
# Make analysis writable for builder swaps
for root, dirs, files in os.walk(os.path.join(dst, "analysis")):
    for f in files:
        os.chmod(os.path.join(root, f), 0o644)
for f in ("run_fixtures.R", "planted_transforms.R"):
    shutil.copy2(os.path.join(gate, "tools/rehearsal/harness", f), os.path.join(dst, "validation", f))
if ra:
    os.makedirs(os.path.join(dst, "analysis/r_a"), exist_ok=True)
    shutil.copy2(ra, os.path.join(dst, "analysis/r_a/main.R"))
if rb:
    os.makedirs(os.path.join(dst, "analysis/r_b"), exist_ok=True)
    shutil.copy2(rb, os.path.join(dst, "analysis/r_b/main.R"))
# Refresh production outputs for poison/reader checks
for role, sub in (("r_a", "r_a"), ("r_b", "r_b")):
    od = os.path.join(dst, "outputs", sub)
    if os.path.isdir(od): shutil.rmtree(od)
    os.makedirs(od)
    r = subprocess.run([RS, "--vanilla", os.path.join(dst, "analysis", sub, "main.R"),
                        os.path.join(dst, "data", "fixture_8row.csv"), od], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"FAIL builder {sub} exit {r.returncode}: {r.stderr[-500:]}")
print("staged", dst)
