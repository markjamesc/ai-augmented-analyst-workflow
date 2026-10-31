# SYNTHETIC rehearsal: negative probes (b, c, e, f, g + control) per REMEDIATION_LIVE_HANDOFF.md on copies of the certified ROOT.  Usage: drive_probes.py ROOT GATE PROBES
import sys, os, json, subprocess, re; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from drive_common import *
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
# 2026-10-31 (card t1665s6948): F1-F6 probes, each a copy of control with one planted defect; the named check must FAIL.
import hashlib
def _fcopy(n): d = f'{P}/{n}'; shutil.rmtree(d, ignore_errors=True); shutil.copytree(f'{P}/control', d, symlinks=True); return d
def _jl(path): return json.load(open(path))
def _jw(path, x): os.chmod(path, 0o644) if os.path.exists(path) else None; json.dump(x, open(path, 'w'), indent=1)
def _sends(d, st, fn):  # apply fn to the ledger send list and to each per-send file
    L = _jl(f'{d}/artifacts/operations/{st}.json'); L['sends'] = fn(L['sends']); _jw(f'{d}/artifacts/operations/{st}.json', L)
    for x in L['sends']:
        q = f'{d}/artifacts/operations/{st}_sends/{x["id"]}.json'
        if os.path.exists(q): _jw(q, x)
def _sha(path): return hashlib.sha256(open(path, 'rb').read()).hexdigest()
def f1(d): _sends(d, 'start', lambda S: [x for x in S if x.get('role') != 'red_team'])
def f2(d):
    cp = f'{d}/captures/finish/S5-i1_capture.json'; c = _jl(cp); c.pop('capture_sha256', None); _jw(cp, c); h = _sha(cp)
    _sends(d, 'finish', lambda S: [dict(x, capture=dict(x['capture'], sha256=h)) if x['id'] == 'S5-i1' else x for x in S])
def f3(d):
    S0 = _jl(f'{d}/artifacts/operations/finish.json')['sends']; n = [x['nonce'] for x in S0 if x['id'] == 'S5-i1'][0]
    _sends(d, 'finish', lambda S: [dict(x, nonce=n) if x['id'] == 'S5-x1' else x for x in S])
def f4(d):
    sw = {'interpreter': 'inference_reviewer', 'inference_reviewer': 'interpreter'}
    _sends(d, 'finish', lambda S: [dict(x, role=sw.get(x.get('role'), x.get('role'))) for x in S])
def f5(d): _sends(d, 'finish', lambda S: [dict(x, attachments=[]) if x['id'] == 'S5-n1' else x for x in S])
def f6(d):
    t = 'transcripts/finish/late_reply.txt.bak'; open(f'{d}/{t}', 'w').write('Late\n'); rp = f'{d}/artifacts/stage5_interpretation_status.json'
    r = _jl(rp); r['late_review'] = {'path': t, 'sha256': _sha(f'{d}/{t}')}; _jw(rp, r)
# F5b (RV-D2/RV-C2, card t1665s6948): each required send must attach every reviewed subject at its current hash; receipt never counts.
def _ref(d, q): return {'path': q, 'sha256': _sha(f'{d}/{q}')}
def f5b_receipt(d): _sends(d, 'finish', lambda S: [dict(x, attachments=[_ref(d, 'artifacts/stage5_interpretation_status.json')]) if x['id'] == 'S5-n1' else x for x in S])
def f5b_ancillary(d): _sends(d, 'finish', lambda S: [dict(x, attachments=[_ref(d, 'outputs/r_a/totals.csv')]) if x['id'] == 'S5-n1' else x for x in S])
def f5b_omit(d): _sends(d, 'finish', lambda S: [dict(x, attachments=[a for a in x['attachments'] if a['path'] != 'docs/stage5/interpretation.md']) if x['id'] == 'S5-n1' else x for x in S])
def f5b_stale(d): _sends(d, 'finish', lambda S: [dict(x, attachments=[dict(a, sha256='0'*64) if a['path'] == 'docs/stage5/interpretation.md' else a for a in x['attachments']]) if x['id'] == 'S5-n1' else x for x in S])
# Plan A (t1674s7005): receipt-side probes.  _strip drops every ref whose path matches rx from a receipt, so the stage has no
# own review subject; the NA guard must then FAIL "review subjects" (never pass vacuously).
def _strip(x, rx):
    if isinstance(x, dict): return {k: _strip(v, rx) for k, v in x.items() if not (isinstance(v, dict) and isinstance(v.get('path'), str) and re.search(rx, v['path']))}
    if isinstance(x, list): return [_strip(v, rx) for v in x if not (isinstance(v, dict) and isinstance(v.get('path'), str) and re.search(rx, v['path']))]
    return x
def _rstrip(d, rp, rx): q = f'{d}/{rp}'; _jw(q, _strip(_jl(q), rx))
def f5b_no_builders(d): _rstrip(d, 'artifacts/stage4_validation_status.json', r'^((builds/frozen|analysis)/.+\.R|receipts/[^/]+\.json)$')
def pa_design_guard(d): _rstrip(d, 'artifacts/stage3_locked_design.json', r'^docs/')
def pa_finish_guard(d): _rstrip(d, 'artifacts/stage5_interpretation_status.json', r'^docs/.+\.md$')
def f5b_builders(d): _sends(d, 'execution', lambda S: [dict(x, attachments=[a for a in x['attachments'] if not a['path'].startswith('builds/')]) if x.get('role') == 'structural reviewer' else x for x in S])
OPSS = lambda c, st: [RS, '--vanilla', 'tools/check_remediation.R', 'operations', f'{P}/{c}', st]
for n, fn, st, chk in [('f1-start-role-dropped', f1, 'start', 'review coverage start role red_team'),
                       ('f2-capture-sha-missing', f2, 'finish', 'review coverage finish capture S5-i1'),
                       ('f3-duplicate-nonce', f3, 'finish', 'review coverage finish unique send ids'),
                       ('f4-roles-swapped', f4, 'finish', 'review coverage finish role interpreter'),
                       ('f5-no-attachments', f5, 'finish', 'review coverage finish role numerical_auditor'),
                       ('f6-odd-reply-name', f6, 'finish', 'review coverage finish reply transcripts/finish/late_reply.txt.bak'),
                       ('f5b-receipt-only', f5b_receipt, 'finish', 'review coverage finish role numerical_auditor'),
                       ('f5b-ancillary-only', f5b_ancillary, 'finish', 'review coverage finish role numerical_auditor'),
                       ('f5b-subject-omitted', f5b_omit, 'finish', 'review coverage finish role numerical_auditor'),
                       ('f5b-subject-stale', f5b_stale, 'finish', 'review coverage finish role numerical_auditor'),
                       ('f5b-builders-omitted', f5b_builders, 'execution', 'review coverage execution role structural reviewer'),
                       ('f5b-no-builders', f5b_no_builders, 'execution', 'review coverage execution review subjects'),
                       ('pa-design-no-record', pa_design_guard, 'design', 'review coverage design review subjects'),
                       ('pa-finish-no-record', pa_finish_guard, 'finish', 'review coverage finish review subjects')]:
    fn(_fcopy(n)); cases.append((n, OPSS(n, st), 1, chk))
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
