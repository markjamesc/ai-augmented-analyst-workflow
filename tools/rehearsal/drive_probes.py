# SYNTHETIC rehearsal: negative probes (a)-(e) per REMEDIATION_LIVE_HANDOFF.md on copies of the certified ROOT.  Usage: drive_probes.py ROOT GATE PROBES
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
cases = [('a early', [RS, '--vanilla', 'tools/check_remediation.R', 'operations', f'{P}/early', 'finish'], 1),
         ('b changed-rb validation', [RS, '--vanilla', 'tools/check_remediation.R', 'validation', f'{P}/changed-rb'], 1),
         ('b changed-rb finalize', [RS, '--vanilla', 'procedure-gate/procedure_gate.R', 'finalize', f'{P}/changed-rb'], 'nonzero_or_uncertified'),
         ('c watchdog', [PY, 'tools/acceptance.py', 'watchdog', R, f'{P}/watchdog.json', '--out', f'{P}/watchdog-result.json'], 1),
         ('d condition', [RS, '--vanilla', 'tools/check_remediation.R', 'operations', f'{P}/condition', 'finish'], 1),
         ('d revocation', [RS, '--vanilla', 'tools/check_remediation.R', 'operations', f'{P}/revocation', 'finish'], 1),
         ('e stale-capture', [PY, 'tools/acceptance.py', 'capture', f'{P}/stale-capture', f'{P}/stale-capture/probe-capture.json', '--out', f'{P}/stale-capture/rejected-capture.json'], 2)]
out = {}
for name, cmd, want in cases:
    code, txt = run(cmd); open(f'{P}/{name.replace(" ", "_")}.txt', 'w').write(txt)
    if want == 'nonzero_or_uncertified':
        c = json.load(open(f'{P}/changed-rb/artifacts/final_certificate.json')); ok = code != 0 or not c.get('certified'); want = 'refuse'
    else: ok = code == want
    out[name] = dict(exit=code, expected=want, ok=ok); print(f'{name}: exit {code} expected {want} -> {"OK" if ok else "UNEXPECTED"}')
json.dump(out, open(f'{P}/probe_results.json', 'w'), indent=1); sys.exit(0 if all(v['ok'] for v in out.values()) else 1)
