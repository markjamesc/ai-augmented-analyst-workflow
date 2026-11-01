"""Rehearsal seed: package manifest observed on this box (the ACC002 manifest records the PC's R 4.6.1; the box has a different R,
so rebuild_env.R correctly FAILs against it).  Values are read from Rscript --vanilla on the box, not typed."""
import json, subprocess, sys, os
RS = '/opt/mamba/envs/r/bin/Rscript'; root = sys.argv[1]
q = lambda e: subprocess.run([RS, '--vanilla', '-e', e], capture_output=True, text=True, check=True).stdout.strip()
m = json.load(open(f'{root}/environment/package_manifest.json'))
m.update(note="REHEARSAL (box) manifest: values observed on the box by Rscript --vanilla via box_manifest.py; replaces the ACC002 PC manifest for box rehearsal only. A live run uses the PC manifest.",
         r_version=q('cat(R.version.string)'), platform=q('cat(R.version$platform)'), os=q('cat(Sys.info()[["sysname"]])'), rscript=RS,
         locale=q('cat(Sys.getlocale())'), timezone=q('cat(Sys.timezone())'), base_packages=f"Base and recommended packages shipped with {q('cat(R.version.string)')}",
         packages=[{"name": p, "version": q(f'cat(as.character(packageVersion("{p}")))'), "library": q(f'cat(dirname(find.package("{p}")))')} for p in ('jsonlite', 'digest')])
p = f'{root}/environment/package_manifest.json'; os.chmod(p, 0o644)
open(p, 'w').write(json.dumps(m, indent=1) + '\n'); print(m['r_version'], m['packages'])
