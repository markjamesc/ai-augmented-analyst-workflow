"""Observe and write environment/package_manifest.json for the machine that will run the analysis.

B2 (STAGE4_RISK_AUDIT): never copy another machine's manifest. Values come from Rscript --vanilla
on THIS host. The next live ACC run executes on this box (R 4.4.3), not the owner PC.
Usage: box_manifest.py ROOT [--run-id RUN] [--note TEXT]
"""
import json, subprocess, sys, os, argparse
RS = os.environ.get("RSCRIPT") or "/opt/mamba/envs/r/bin/Rscript"
ap = argparse.ArgumentParser()
ap.add_argument("root")
ap.add_argument("--run-id")
ap.add_argument("--note")
a = ap.parse_args()
root = a.root

def q(expr):
    r = subprocess.run([RS, "--vanilla", "-e", expr], capture_output=True, text=True, check=True)
    return r.stdout.strip()

path = os.path.join(root, "environment", "package_manifest.json")
m = json.load(open(path)) if os.path.isfile(path) else {}
note = a.note or (
    "Observed on this execution host by tools/rehearsal/box_manifest.py via Rscript --vanilla. "
    "Regenerated per run for the live machine; do not copy from another platform."
)
pkgs = []
for name in ("jsonlite", "digest"):
    pkgs.append({
        "name": name,
        "version": q(f'cat(as.character(packageVersion("{name}")))'),
        "library": q(f'cat(dirname(find.package("{name}")))'),
    })
m.update(
    note=note,
    r_version=q("cat(R.version.string)"),
    platform=q("cat(R.version$platform)"),
    os=q('cat(Sys.info()[["sysname"]])'),
    rscript=os.path.abspath(RS),
    locale=q("cat(Sys.getlocale())"),
    timezone=q("cat(Sys.timezone())"),
    base_packages="Base and recommended packages shipped with " + q("cat(R.version.string)"),
    packages=pkgs,
)
if a.run_id:
    m["run_id"] = a.run_id
os.makedirs(os.path.dirname(path), exist_ok=True)
if os.path.exists(path):
    os.chmod(path, 0o644)
open(path, "w").write(json.dumps(m, indent=1) + "\n")
print(m["r_version"], m["platform"], m["packages"])
