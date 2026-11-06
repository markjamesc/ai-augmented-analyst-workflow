#!/usr/bin/env python3
"""Pre-send check: every required subject path is present in --attach (M2 / D-08 class).

Usage: check_attachments.py --require PATH [PATH ...] --attach PATH [PATH ...]
Exit 0 if every required path is in attach (path-normalized); else exit 1 listing gaps.
"""
import argparse, os, sys
ap = argparse.ArgumentParser()
ap.add_argument("--require", nargs="+", required=True)
ap.add_argument("--attach", nargs="+", required=True)
a = ap.parse_args()
norm = lambda p: os.path.normpath(p).replace(os.sep, "/")
have = {norm(x) for x in a.attach}
need = [norm(x) for x in a.require]
missing = [x for x in need if x not in have]
if missing:
    sys.exit("FAIL attachments missing: " + ", ".join(missing))
print("attachments complete", len(need))
