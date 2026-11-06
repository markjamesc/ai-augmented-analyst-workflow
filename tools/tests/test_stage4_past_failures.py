#!/usr/bin/env python3
"""Past Stage 4 failure regressions (ACC002–ACC004S) as automated tests.

Each case encodes a failure that previously halted or forced a successor live run.
Exit 0 only if every case PASSes.
"""
import json, os, sys, shutil, subprocess, tempfile, hashlib
GATE = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RS = os.environ.get('RSCRIPT', '/opt/mamba/envs/r/bin/Rscript')
PY = sys.executable
n = bad = 0

def ok(name, cond, detail=''):
    global n, bad
    n += 1
    bad += (not cond)
    print(('PASS ' if cond else 'FAIL ') + name + ((' :: ' + detail) if detail and not cond else ''))

def sha(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest()

# --- B1: code-independent planted defects catch ACC004S builders; no-op transform FAILs ---
ok('B1 planted_defects PASS on ACC004S confirmation artifact',
   os.path.isfile('/tmp/planted_acc004s2/outputs/verification/planted_defects.json') and
   json.load(open('/tmp/planted_acc004s2/outputs/verification/planted_defects.json'))['status'] == 'PASS')
ok('B1 planted_defects PASS on ACC002 builders',
   os.path.isfile('/tmp/planted_acc002b/outputs/verification/planted_defects.json') and
   json.load(open('/tmp/planted_acc002b/outputs/verification/planted_defects.json'))['status'] == 'PASS')
# no-op transform
r = subprocess.run([RS, '--vanilla', '-e',
    f'source("{GATE}/tools/rehearsal/harness/planted_transforms.R"); '
    'dir.create("/tmp/noop_xf", showWarnings=FALSE); '
    'quit(status=if (isTRUE(transform_threshold("/tmp/noop_xf"))) 0 else 3)'],
    capture_output=True, text=True)
ok('B1 no-op threshold transform returns not-planted (exit 3)', r.returncode == 3)

# --- B2: environment must match observed host R (box 4.4.3), not ACC002 Windows 4.6.1 ---
td = tempfile.mkdtemp(prefix='b2env_')
os.makedirs(f'{td}/environment')
# seed with wrong ACC002-like manifest
open(f'{td}/environment/package_manifest.json', 'w').write(json.dumps({
    'run_id': 'ACC-SMALL-REMEDIATION-002', 'r_version': 'R version 4.6.1 (2026-06-24 ucrt)',
    'platform': 'x86_64-w64-mingw32', 'os': 'Windows', 'packages': []
}) + '\n')
subprocess.check_call([PY, f'{GATE}/tools/rehearsal/box_manifest.py', td, '--run-id', 'TEST-B2'])
m = json.load(open(f'{td}/environment/package_manifest.json'))
ok('B2 observed r_version is 4.4.3 on this box', '4.4.3' in m.get('r_version', ''))
ok('B2 not Windows/ucrt from ACC002', 'ucrt' not in m.get('r_version', '') and m.get('os') != 'Windows')
# rebuild_env must PASS against observed manifest
shutil.copytree('/workspace/live_20261104/ACC004S/environment', f'{td}/environment', dirs_exist_ok=True)
# re-observe after copy
subprocess.check_call([PY, f'{GATE}/tools/rehearsal/box_manifest.py', td, '--run-id', 'TEST-B2'])
shutil.copy2('/workspace/live_20261104/ACC004S/environment/rebuild_env.R', f'{td}/environment/rebuild_env.R')
os.makedirs(f'{td}/outputs/verification', exist_ok=True)
r = subprocess.run([RS, '--vanilla', f'{td}/environment/rebuild_env.R', td], capture_output=True, text=True)
ok('B2 rebuild_env PASS with observed box manifest', r.returncode == 0 and 'PASS' in r.stdout)

# --- missing fixture-manifest source section (ACC004 -> ACC004S) ---
man = json.load(open('/workspace/live_20261104/ACC004/validation/fixtures/manifest.json'))
ok('ACC004 past failure: manifest lacked source section', 'source' not in man)
man_s = json.load(open('/workspace/live_20261104/ACC004S/validation/fixtures/manifest.json'))
ok('ACC004S fix present: manifest has source section', 'source' in man_s and isinstance(man_s['source'], dict))
# Gate-like check helper
def manifest_source_ok(path):
    m = json.load(open(path))
    s = m.get('source')
    return isinstance(s, dict) and 'path' in s and 'sha256' in s
ok('manifest source check rejects ACC004', not manifest_source_ok('/workspace/live_20261104/ACC004/validation/fixtures/manifest.json'))
ok('manifest source check accepts ACC004S', manifest_source_ok('/workspace/live_20261104/ACC004S/validation/fixtures/manifest.json'))

# --- L3: methodology runs after final structural (in s4b), not after first NEEDS_REVIEW ---
s4a = open(f'{GATE}/tools/rehearsal/drive_s4a.py').read()
s4b = open(f'{GATE}/tools/rehearsal/drive_s4b.py').read()
ok('L3 drive_s4a runs structural_review_v2 and does not run check_methodology',
   'structural_review_v2.R' in s4a and 'check_methodology.R' not in s4a)
ok('L3 drive_s4b runs check_methodology after structural rerun',
   s4b.index('structural_review_v2.R') < s4b.index('check_methodology.R') and 'check_lineage_v2.R' in s4b)

# --- L4: move_aside never deletes; enables rerun ---
td = tempfile.mkdtemp(prefix='l4_')
os.makedirs(f'{td}/outputs/verification')
open(f'{td}/outputs/verification/run_fixtures_status.json', 'w').write('{"status":"FAIL"}\n')
r = subprocess.run([PY, f'{GATE}/tools/move_aside.py', td, 'outputs/verification/run_fixtures_status.json'], capture_output=True, text=True)
ok('L4 move_aside relocates write-once file', r.returncode == 0 and not os.path.exists(f'{td}/outputs/verification/run_fixtures_status.json'))
ok('L4 moved file still exists under superseded/attempt_*', any(
    os.path.isfile(os.path.join(dp, f)) for dp, dn, fn in os.walk(f'{td}/outputs/superseded') for f in fn if f.endswith('.json')))

# --- L5: ledger ignores non-JSON; packet validates attachments before write ---
# Use a mini run_state
td = tempfile.mkdtemp(prefix='l5_')
os.makedirs(f'{td}/artifacts/procedure'); os.makedirs(f'{td}/artifacts/operations/start_sends')
open(f'{td}/artifacts/procedure/run_state.json', 'w').write(json.dumps({
    'run_id': 'L5TEST', 'current_step': 'start'}) + '\n')
open(f'{td}/artifacts/operations/start_sends/S1-01.json', 'w').write(json.dumps({
    'id': 'S1-01', 'ai': 'X', 'role': 'red_team', 'send_kind': 'review', 'nonce': 'a'*16,
    'packet': {'path': 'p', 'sha256': '0'*64}, 'attachments': [], 'reply': {'path': 't', 'sha256': '0'*64},
    'capture': {'path': 'c', 'sha256': '0'*64}, 'captured_at_utc': '2026-01-01T00:00:00Z', 'depends_on': []}) + '\n')
open(f'{td}/artifacts/operations/start_sends/README.txt', 'w').write('notes must not crash ledger\n')
r = subprocess.run([PY, f'{GATE}/tools/runkit.py', 'ledger', td, 'start'], capture_output=True, text=True)
ok('L5 ledger ignores non-JSON notes in *_sends', r.returncode == 0)
# attachment missing before write must not create message.md
os.makedirs(f'{td}/artifacts/procedure', exist_ok=True)
open(f'{td}/artifacts/procedure/run_state.json', 'w').write(json.dumps({'run_id': 'L5TEST', 'current_step': 'start'}) + '\n')
open(f'{td}/msg.md', 'w').write('hello\n')
r = subprocess.run([PY, f'{GATE}/tools/runkit.py', 'packet', td, 'start', 'S1-miss',
                    '--ai', 'X', '--role', 'red_team', '--kind', 'review', '--message', f'{td}/msg.md',
                    '--attach', 'does_not_exist.txt'], capture_output=True, text=True)
ok('L5/M2 packet refuses missing attachment before write', r.returncode != 0)
ok('L5/M2 no orphan message.md for failed packet', not os.path.exists(f'{td}/packets/start/S1-miss/message.md'))

# --- M2: check_attachments catches D-08-class gap ---
r = subprocess.run([PY, f'{GATE}/tools/check_attachments.py',
                    '--require', 'docs/stage3/DESIGN_GATE_RECORD.md', 'validation/fixtures/manifest.json',
                    '--attach', 'docs/stage3/DESIGN_GATE_RECORD.md'], capture_output=True, text=True)
ok('M2 check_attachments fails when a required subject is missing', r.returncode != 0 and 'manifest.json' in r.stderr+r.stdout)
r = subprocess.run([PY, f'{GATE}/tools/check_attachments.py',
                    '--require', 'a.md', 'b.md', '--attach', 'b.md', 'a.md'], capture_output=True, text=True)
ok('M2 check_attachments passes when all required subjects attached', r.returncode == 0)

# --- L6: drive_s123 renames lineage v1 -> v2 in composed lock ---
s123 = open(f'{GATE}/tools/rehearsal/drive_s123.py').read()
ok('L6 drive_s123 renames check_lineage.R to v2 in lock', 'check_lineage_v2.R' in s123 and '_rename_lineage' in s123)

# --- L2: carry_builds requires transcripts with code ---
td_src = tempfile.mkdtemp(prefix='l2s_'); td_dst = tempfile.mkdtemp(prefix='l2d_')
# missing transcript must fail
os.makedirs(f'{td_src}/builds/frozen/S4-RA1/analysis/r_a'); os.makedirs(f'{td_src}/builds/frozen/S4-RB1/analysis/r_b')
open(f'{td_src}/builds/frozen/S4-RA1/analysis/r_a/main.R', 'w').write('a\n')
open(f'{td_src}/builds/frozen/S4-RB1/analysis/r_b/main.R', 'w').write('b\n')
r = subprocess.run([PY, f'{GATE}/tools/carry_builds.py', td_src, td_dst, '--ra', 'S4-RA1', '--rb', 'S4-RB1'], capture_output=True, text=True)
ok('L2 carry_builds refuses code without transcripts', r.returncode != 0)

# --- ACC004S closeout: planted line-edit mismatch is fixed (harness has no literal ACC002 edit strings) ---
rf = open(f'{GATE}/tools/rehearsal/harness/run_fixtures.R').read()
ok('B1 harness has no ACC002-specific amounts[present] >= 10 edit', 'amounts[present] >= 10' not in rf)
ok('B1 harness uses output_wrapper planting', 'output_wrapper' in rf or 'planting = "output_wrapper"' in rf or 'output wrappers' in rf.lower())

print(f'\n{n - bad}/{n} PASS')
sys.exit(0 if bad == 0 else 1)
