"""structural_review_v2.R (tools/rehearsal/harness, owner card t1637s6856): an absent dispositions file is recorded as
dispositions_present=false with no path+sha256 reference, so the gate's closure walk (m_inventory over m_refs) succeeds.
Usage: test_structural_absent.py [FIXTURE_ROOT]  (a run root whose Stage 4 builds and dispositions exist; default dev1)."""
import os, sys, json, shutil, subprocess, tempfile
H = os.path.dirname(os.path.abspath(__file__)); G = os.path.abspath(f'{H}/../..'); RS = '/opt/mamba/envs/r/bin/Rscript'
SRC = sys.argv[1] if len(sys.argv) > 1 else '/workspace/reh/dev1'
n = bad = 0
def ok(name, c):
    global n, bad; n += 1; bad += (not c); print(('PASS ' if c else 'FAIL ') + name)
r = tempfile.mkdtemp()
for x in ['analysis', 'validation', 'evidence_snapshots', 'transcripts', 'builds', 'artifacts/stage3_locked_design.json', 'outputs/verification/structural_dispositions.json']:
    s, d = f'{SRC}/{x}', f'{r}/{x}'; os.makedirs(os.path.dirname(d), exist_ok=True)
    shutil.copytree(s, d) if os.path.isdir(s) else shutil.copy(s, d)
shutil.copy(f'{G}/tools/rehearsal/harness/structural_review_v2.R', f'{r}/validation/structural_review_v2.R')
disp = f'{r}/outputs/verification/structural_dispositions.json'; keep = open(disp, 'rb').read(); os.chmod(disp, 0o644); os.remove(disp)
for f in os.listdir(f'{r}/outputs/verification'):
    if f.startswith('structural') and f.endswith('.json'): os.remove(f'{r}/outputs/verification/{f}')
shutil.rmtree(f'{r}/outputs/verification/runs', ignore_errors=True)
def run():
    p = subprocess.run([RS, '--vanilla', f'{r}/validation/structural_review_v2.R', r], capture_output=True, text=True); return p.returncode
def closure():
    code = f'suppressMessages(library(jsonlite)); source("{G}/methodology/contracts.R"); x <- tryCatch(m_inventory(m_refs(m_read("{r}/outputs/verification/structural.json")), "{r}"), error=function(e) conditionMessage(e)); cat(if (is.character(x)) x else "CLOSED")'
    return subprocess.run([RS, '--vanilla', '-e', code], capture_output=True, text=True).stdout.strip()
rc = run(); o = json.load(open(f'{r}/outputs/verification/structural.json'))
ok('absent: NEEDS_REVIEW (exit 3)', rc == 3 and o['status'] == 'NEEDS_REVIEW')
ok('absent: dispositions_present is false', o.get('dispositions_present') is False)
ok('absent: no reference to the dispositions path anywhere', 'structural_dispositions.json' not in json.dumps(o))
ok('absent: no path+null-sha256 pair', '"sha256": null' not in json.dumps(o))
ok('absent: gate closure walk succeeds', closure() == 'CLOSED')
sys.path.insert(0, f'{G}/tools'); import scope_refs as SR
shutil.rmtree(f'{r}/evidence_snapshots/structural_needs_review'); snp = SR.snapshot(r, 'outputs/verification/structural.json', 'structural_needs_review')
os.makedirs(f'{r}/outputs/superseded', exist_ok=True); os.rename(f'{r}/outputs/verification/structural.json', f'{r}/outputs/superseded/s.json')
dj = json.loads(keep)  # temp fixture only: re-bind the copied dispositions to the snapshot of the NEW script's NEEDS_REVIEW report
def rb(x):
    if isinstance(x, dict):
        if x.get('path') == snp: return {"path": snp, "sha256": SR.sha(f'{r}/{snp}')}
        return {k: rb(v) for k, v in x.items()}
    return [rb(v) for v in x] if isinstance(x, list) else x
open(disp, 'w').write(json.dumps(rb(dj), indent=1)); rc = run(); o = json.load(open(f'{r}/outputs/verification/structural.json'))
ok('present: PASS (exit 0)', rc == 0 and o['status'] == 'PASS')
ok('present: dispositions_present true and hash-bound ref', o.get('dispositions_present') is True and o['dispositions']['path'] == 'outputs/verification/structural_dispositions.json' and len(o['dispositions']['sha256']) == 64)
ok('present: gate closure walk succeeds', closure() == 'CLOSED')
shutil.rmtree(r); print(f'{n - bad}/{n} passed'); sys.exit(1 if bad else 0)
