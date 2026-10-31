# SYNTHETIC rehearsal: negative probes (b, c, e, f, g + control) per REMEDIATION_LIVE_HANDOFF.md on copies of the certified ROOT.  Usage: drive_probes.py ROOT GATE PROBES
import sys, os, json, subprocess; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from drive_common import *
R, G, P = [os.path.abspath(x) for x in sys.argv[1:4]]
def run(cmd): r = subprocess.run(cmd, cwd=G, capture_output=True, text=True); return r.returncode, r.stdout + r.stderr
# Own-tooling fix: the certified ROOT carries 0444 locked files on POSIX and copytree keeps modes, so prepare_live_probes.py
# could not alter its copies.  Probe from a writable staging copy (same bytes, u+w), never touching ROOT; check prepare's exit.
import shutil, stat; S = P + '_src'; shutil.rmtree(S, ignore_errors=True); shutil.copytree(R, S, symlinks=True)
for dp, dn, fn in os.walk(S):
    for x in dn + fn: q = os.path.join(dp, x); (not os.path.islink(q)) and os.chmod(q, os.stat(q).st_mode | stat.S_IWUSR)
code, txt = run([PY, 'tools/prepare_live_probes.py', S, P]); print(txt.strip()[-500:])
if code != 0: raise SystemExit(f'prepare_live_probes failed ({code})')
# 2026-10-31 (option B): a and d retired with their cut rules; control, f dropped-review and g stale-reply added.
# A 4th element names a check that must be among the FAILs, so a probe cannot pass for an unrelated reason.
OPS = lambda c: [RS, '--vanilla', 'tools/check_remediation.R', 'operations', f'{P}/{c}', 'finish']
cases = [('control', OPS('control'), 0),
         ('b changed-rb validation', [RS, '--vanilla', 'tools/check_remediation.R', 'validation', f'{P}/changed-rb'], 1),
         ('b changed-rb finalize', [RS, '--vanilla', 'procedure-gate/procedure_gate.R', 'finalize', f'{P}/changed-rb'], 'nonzero_or_uncertified'),
         ('c watchdog', [PY, 'tools/acceptance.py', 'watchdog', R, f'{P}/watchdog.json', '--out', f'{P}/watchdog-result.json'], 1),
         ('e stale-capture', [PY, 'tools/acceptance.py', 'capture', f'{P}/stale-capture', f'{P}/stale-capture/probe-capture.json', '--out', f'{P}/stale-capture/rejected-capture.json'], 2),
         ('f dropped-review', OPS('dropped-review'), 1, 'review coverage finish role numerical_auditor'),
         ('g stale-reply', OPS('stale-reply'), 1, 'review coverage finish distinct replies')]
def failed(txt):
    try: return [c['check'] for c in json.loads(txt[txt.index('['):]) if c.get('result') != 'PASS']
    except Exception: return None
out = {}
for case in cases:
    name, cmd, want = case[:3]; code, txt = run(cmd); open(f'{P}/{name.replace(" ", "_")}.txt', 'w').write(txt)
    if want == 'nonzero_or_uncertified':
        c = json.load(open(f'{P}/changed-rb/artifacts/final_certificate.json')); ok = code != 0 or not c.get('certified'); want = 'refuse'
    else: ok = code == want
    if len(case) > 3: f = failed(txt) or []; ok = ok and any(case[3] in c for c in f)
    out[name] = dict(exit=code, expected=want, ok=ok); print(f'{name}: exit {code} expected {want} -> {"OK" if ok else "UNEXPECTED"}')
json.dump(out, open(f'{P}/probe_results.json', 'w'), indent=1); sys.exit(0 if all(v['ok'] for v in out.values()) else 1)
