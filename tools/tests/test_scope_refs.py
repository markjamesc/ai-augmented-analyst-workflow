# Tests for tools/scope_refs.py (positive and negative). Run: python3 tools/tests/test_scope_refs.py
import tempfile, json, os, sys, tempfile, hashlib, subprocess, shutil
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..')); import scope_refs as S
n = 0; bad = 0
def ok(name, cond):
    global n, bad; n += 1; bad += (not cond); print(('PASS ' if cond else 'FAIL ') + name)
def W(root, p, x):
    os.makedirs(os.path.dirname(os.path.join(root, p)) or root, exist_ok=True)
    b = (json.dumps(x) if not isinstance(x, (bytes, str)) else x); b = b.encode() if isinstance(b, str) else b
    open(os.path.join(root, p), 'wb').write(b); return {"path": p, "sha256": hashlib.sha256(b).hexdigest()}
def fails(f):
    try: f(); return False
    except SystemExit as e: return str(e).startswith('FAIL')
def build():
    r = tempfile.mkdtemp()
    c1 = W(r, 'outputs/verification/checks.csv', 'pass1\n')                       # live file, later overwritten
    W(r, 'outputs/verification/runs/verify_run_pass1/du.json', {"checks": c1})     # pass archive cites live path
    sb = W(r, 'sandbox/outputs/verification/replay_report.txt', 'sandbox\n')
    W(r, 'outputs/verification/replay_report.txt', 'root differs\n')               # same rel path at root, other bytes
    W(r, 'sandbox/outputs/verification/replay.json', {"report": {"path": "outputs/verification/replay_report.txt", "sha256": sb['sha256']}})
    W(r, 'outputs/verification/versioned/T1/tests/x.txt', 'x\n')
    W(r, 'outputs/verification/versioned/T1/test_versions.json', {"t": {"path": "tests/x.txt", "sha256": hashlib.sha256(b'x\n').hexdigest()}})
    return r
r = build()
# baseline: citing the historical records directly is caught by the guard
W(r, 'receipts/a.json', {"du": {"path": "outputs/verification/runs/verify_run_pass1/du.json", "sha256": S.sha(os.path.join(r, 'outputs/verification/runs/verify_run_pass1/du.json'))}})
ok('guard: receipt citing a historical pass archive fails', any('historical' in e for e in S.guard(r, ['receipts/a.json'])))
du = S.snapshot(r, 'outputs/verification/runs/verify_run_pass1/du.json', 'du_pass1')
rp = S.snapshot(r, 'sandbox/outputs/verification/replay.json', 'replay')
tv = S.snapshot(r, 'outputs/verification/versioned/T1/test_versions.json', 'tv')
W(r, 'receipts/b.json', {k: {"path": p, "sha256": S.sha(os.path.join(r, p))} for k, p in [('du', du), ('rp', rp), ('tv', tv)]})
ok('guard: receipt citing snapshots passes', S.guard(r, ['receipts/b.json']) == [])
ok('snapshot: sandbox-relative ref resolved to the sandbox file by hash, not the root file',
   json.load(open(os.path.join(r, rp)))['report']['snapshot_of']['resolved'] == 'sandbox/outputs/verification/replay_report.txt')
W(r, 'outputs/verification/checks.csv', 'pass2 overwrote\n')
ok('guard: snapshot survives a later overwrite of the live path', S.guard(r, ['receipts/b.json']) == [])
ok('snapshot: write-once (same name refused)', fails(lambda: S.snapshot(r, 'outputs/verification/runs/verify_run_pass1/du.json', 'du_pass1')))
ok('snapshot: an already-stale ref FAILS (nothing guessed)', fails(lambda: S.snapshot(r, 'outputs/verification/runs/verify_run_pass1/du.json', 'du_late')))
ok('guard: stale original after overwrite is caught', any('stale' in e for e in S.guard(r, ['outputs/verification/runs/verify_run_pass1/du.json'])))
p = os.path.join(r, du); o = json.load(open(p)); o['checks']['path'] = 'outputs/verification/checks.csv'; o['checks']['sha256'] = S.sha(os.path.join(r, 'outputs/verification/checks.csv'))
os.chmod(p, 0o644); open(p, 'w').write(json.dumps(o)); W(r, 'receipts/c.json', {"du": {"path": du, "sha256": S.sha(p)}})
ok('guard: a snapshot citing outside its own scope fails', any('outside itself' in e for e in S.guard(r, ['receipts/c.json'])))
cp = os.path.join(r, json.load(open(os.path.join(r, 'evidence_snapshots/tv/manifest.json')))['entries'][0]['copy']['path']); os.chmod(cp, 0o644); open(cp, 'a').write('tamper')
ok('guard: tampered snapshot copy fails', any('stale' in e for e in S.guard(r, ['receipts/b.json'])))
# cross-check with the gate's own m_inventory (if Rscript available)
RS = os.environ.get('RS') or shutil.which('Rscript')
if RS:
    r2 = build(); a = S.snapshot(r2, 'outputs/verification/runs/verify_run_pass1/du.json', 'd'); b = S.snapshot(r2, 'sandbox/outputs/verification/replay.json', 'p')
    W(r2, 'outputs/verification/checks.csv', 'later\n')
    G = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
    code = f'''suppressMessages(library(jsonlite)); source("{G}/methodology/contracts.R"); r <- "{r2}"
      x <- m_inventory(list(list(path="{a}",sha256="{S.sha(os.path.join(r2,a))}"),list(path="{b}",sha256="{S.sha(os.path.join(r2,b))}")), r)
      y <- tryCatch(m_inventory(list(list(path="outputs/verification/runs/verify_run_pass1/du.json",sha256="{S.sha(os.path.join(r2,'outputs/verification/runs/verify_run_pass1/du.json'))}")), r), error=function(e) list(ok=FALSE))
      cat(is.list(x) && !isFALSE(x$ok), is.list(y) && !isFALSE(y$ok))'''
    out = subprocess.run([RS, '--vanilla', '-e', code], capture_output=True, text=True)
    ok('m_inventory: snapshots close, original pass archive does not (gate agrees with guard)', out.stdout.strip().endswith('TRUE FALSE') or print(out.stdout, out.stderr))
# 'attempt' naming (owner card t1636s6840): the gate's own output name is not read as historical, so no allowlist is needed;
# the pattern is unchanged and still catches attempt-numbered records.
ok('pattern: gate output artifacts/workflow-attempts/attempt-<hex>.json is not historical', not S.HIST.search('artifacts/workflow-attempts/attempt-1a2b3c.json'))
for h in ['docs/stage3/superseded/x.md', 'outputs/x_attempt1.json', 'captures/S4_capture_check_attempt1.json', 'outputs/verification/runs/verify_run_pass1/du.json', 'outputs/verification/versioned/T1/a.json']:
    ok(f'pattern: still historical {h}', bool(S.HIST.search(h)))
# atomic snapshot: an unresolvable ref leaves no partial snapshot, and a later good snapshot of the same name succeeds
r3 = build(); W(r3, 'outputs/bad.json', json.dumps({"x": {"path": "nowhere.csv", "sha256": "0" * 64}}))
try: S.snapshot(r3, 'outputs/bad.json', 'bad'); ok('atomic: bad snapshot refused', False)
except SystemExit: ok('atomic: bad snapshot refused', True)
ok('atomic: nothing left behind', not os.path.exists(os.path.join(r3, S.SNAP, 'bad')) and not any(n.startswith('.staging') for n in (os.listdir(os.path.join(r3, S.SNAP)) if os.path.isdir(os.path.join(r3, S.SNAP)) else [])))
W(r3, 'outputs/bad.json', '{"x": 1}'); t3 = S.snapshot(r3, 'outputs/bad.json', 'bad')
ok('atomic: retry after fix succeeds, files read-only', os.path.isfile(os.path.join(r3, t3)) and not os.access(os.path.join(r3, t3), os.W_OK))
# scoped replay exception (owner card t1637s6850, option (a))
def rroot(begins, rec, cited='outputs/verification/runs/methodology_20261031T120500Z/session_probe.R', citer='outputs/verification/replay.json'):
    r = tempfile.mkdtemp(); W(r, cited, 'probe\n')
    for i, b in enumerate(begins): W(r, f'artifacts/procedure/checks/execution-begin-{i}.json', json.dumps({"step": "execution", "phase": "begin", "result": "PASS", "checked_at_utc": b}))
    W(r, 'outputs/verification/replay.json', json.dumps({"status": "PASS", "recorded_at_utc": rec, "report": {"path": cited, "sha256": S.sha(os.path.join(r, cited))}} if citer == 'outputs/verification/replay.json' else {"status": "PASS", "recorded_at_utc": rec}))
    if citer != 'outputs/verification/replay.json': W(r, citer, json.dumps({"recorded_at_utc": rec, "report": {"path": cited, "sha256": S.sha(os.path.join(r, cited))}}))
    W(r, 'receipts/methodology.json', json.dumps({"dep": {"path": citer, "sha256": S.sha(os.path.join(r, citer))}}))
    return S.guard(r, ['receipts/methodology.json'])
B, REC = '2026-10-31T12:00:00Z', '2026-10-31T12:06:00Z'
ok('replay exception: positive (this execution)', rroot([B], REC) == [])
ok('replay exception: another runs/ dir refused', rroot([B], REC, cited='outputs/verification/runs/structural_20261031T120500Z/a.json') != [])
ok('replay exception: verify_run_pass1 refused', rroot([B], REC, cited='outputs/verification/runs/verify_run_pass1/checks.csv') != [])
ok('replay exception: nested path under methodology dir refused', rroot([B], REC, cited='outputs/verification/runs/methodology_20261031T120500Z/sub/a.R') != [])
ok('replay exception: replay from another run (written before this execution began) refused', rroot(['2026-10-31T13:00:00Z'], REC) != [])
ok('replay exception: replay from an earlier execution begin of this run refused', rroot([B, '2026-10-31T12:10:00Z'], REC) != [])
ok('replay exception: methodology dir outside [begin, recorded] refused', rroot([B], REC, cited='outputs/verification/runs/methodology_20261031T115900Z/session_probe.R') != [])
ok('replay exception: no execution-begin record refused', rroot([], REC) != [])
ok('replay exception: different citing file refused', rroot([B], REC, citer='outputs/verification/replay_copy.json') != [])
print(f'{n - bad}/{n} passed'); sys.exit(1 if bad else 0)
