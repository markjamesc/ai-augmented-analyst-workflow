# ACC002 known-gap replay (owner card t1674s7005).  ACC002 predates R1/F1-F6 (no role field, no capture_sha256, split execution
# ledgers), so its replay cannot pass the current gate.  This test pins TODAY's failing checks per stage: the replay must fail
# exactly these, so a new false rejection (or a silently fixed one) shows up.  A second, passing check confirms the live replies
# themselves are intact: every captured reply matches its recorded sha256 and ends with its packet's END_REPLY line.
# Usage: test_acc002_known_gap.py ACC002_ROOT_COPY   (a writable-or-not COPY; never the original live root).  RSCRIPT=path to Rscript.
import sys, os, json, glob, hashlib, subprocess, shutil
G = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')); R = os.path.abspath(sys.argv[1])
RS = os.environ.get('RSCRIPT') or shutil.which('Rscript') or 'Rscript'
M = 'Methodology review coverage '
PINNED = {
 'start': [M + f'start reply transcripts/start/{s}_reply.md' for s in ('S1-01', 'S1-04', 'S1-05')] + [M + 'start role independent_reconstruction', M + 'start role red_team'] + [M + f'start capture {s}' for s in ('S1-01', 'S1-04', 'S1-05')],
 'framing': [M + f'framing reply transcripts/framing/S2-0{i}_reply.md' for i in range(1, 6)] + [M + f'framing role {r}' for r in ('framing_builder', 'decision_fit_review', 'framing_red_team', 'cross_review')] + [M + f'framing capture S2-0{i}' for i in range(1, 6)],
 'design': [M + f'design reply transcripts/design/D-0{i}_reply.md' for i in range(1, 4)] + [M + f'design role {r}' for r in ('designer_a', 'designer_b', 'risk_reviewer', 'cross_review')] +
           [M + f'design capture {s}' for s in ('D-C1', 'D-C2', 'D-C3', 'D-01', 'D-02', 'D-03', 'D-04', 'D-05', 'D-06', 'D-07a', 'D-07b', 'D-09', 'D-10', 'D-08', 'D-11', 'D-12a', 'D-12b', 'D-13', 'D-12c-a', 'D-12c-b', 'D-14', 'D-12d')],
 # Execution: 'review subjects' no longer fails under the Plan A path rule (analysis/*.R reached via receipts/*.json); it did at 52dd52c.
 'execution': ['Methodology operations ledger execution'] + [M + f'execution reply transcripts/execution/S4-e{i}_reply.md' for i in (1, 2, 3)] + [M + 'execution role structural reviewer', 'Methodology operations evidence closure'],
}
TOTAL = {'start': 17, 'framing': 25, 'design': 57, 'execution': 10}
n = bad = 0
def ok(name, cond, extra=''):
    global n, bad; n += 1; bad += (not cond); print(('PASS ' if cond else 'FAIL ') + name + (f' :: {extra}' if extra and not cond else ''))
for st, want in PINNED.items():
    p = subprocess.run([RS, '--vanilla', 'tools/check_remediation.R', 'operations', R, st], cwd=G, capture_output=True, text=True); t = p.stdout + p.stderr
    try: c = json.loads(t[t.index('['):])
    except Exception: c = None
    got = [x['check'] for x in c if x.get('result') != 'PASS'] if c else None
    ok(f'ACC002 {st}: fails exactly the {len(want)} pinned known-gap checks of {TOTAL[st]}', c is not None and p.returncode != 0 and len(c) == TOTAL[st] and sorted(got) == sorted(want),
       f'new={sorted(set(got or []) - set(want))} fixed={sorted(set(want) - set(got or []))} total={len(c) if c else None}')
# Passing integrity check: every captured live reply is byte-exact and ends with its END_REPLY line.
sends = []
for f in sorted(glob.glob(f'{R}/artifacts/operations/*.json')):
    if f.endswith(('_transcript_index.json', 'revocations.json')): continue
    d = json.load(open(f, encoding='utf-8-sig'))
    sends += [x for x in (d.get('sends') or []) if isinstance(x, dict) and isinstance(x.get('reply'), dict)]
probs = []
for x in sends:
    q = os.path.join(R, x['reply']['path'])
    if not os.path.isfile(q): probs.append(f'{x["id"]}: reply missing'); continue
    b = open(q, 'rb').read()
    if hashlib.sha256(b).hexdigest() != x['reply']['sha256']: probs.append(f'{x["id"]}: reply hash'); continue
    pk = os.path.join(R, x['packet']['path']); m = (json.load(open(pk, encoding='utf-8-sig')).get('end_marker') if os.path.isfile(pk) else None) or f'END_REPLY {x["id"]} {x["nonce"]}'
    last = [l for l in b.decode('utf-8', 'replace').splitlines() if l.strip()][-1:]
    if not last or last[0].strip() != m: probs.append(f'{x["id"]}: END_REPLY')
ok(f'ACC002 every captured reply ({len(sends)}) matches its sha256 and ends with its END_REPLY line', sends and not probs, '; '.join(probs[:10]))
print(f'{n - bad}/{n} passed'); sys.exit(1 if bad else 0)
