# Stage 4 part A: begin execution, builder sends (SYNTHETIC replies carrying the ACC002 accepted code), freeze+install, reviews,
# then the locked pipeline through structural_review_v2.  Usage: drive_s4a.py ROOT GATE
import sys, os, re, json, time, shutil
sys.path.insert(0, os.path.dirname(__file__)); from drive_common import *
root, gate = sys.argv[1:3]; d = D(root, gate)
d.gate('begin', 'execution'); time.sleep(3)
B = {'S4-RA1': ('ChatGPT', 'R-A', 'r_a'), 'S4-RB1': ('DeepSeek', 'R-B', 'r_b')}
for sid, (ai, role, sub) in B.items():
    code = open(d.p(f'analysis/{sub}/main.R'), encoding='utf-8').read()
    body = f'{LAB}\nStand-in builder reply: the code below is the ACC002 accepted {role} script, reproduced verbatim (not newly written by an AI).\n\n```r\n{code}```\n\nVERDICT: BUILT'
    d.send('execution', sid, ai, f'builder {role}', 'builder', f'{LAB}\nBuild {role} from the locked sections.\n', attach=['artifacts/stage3_locked_design.json', 'data/fixture_8row.csv'],
           reply_body=body, extra=('--builder-role', role, '--locked-sections', '--accepted-code'))
    rep = open(d.p(f'transcripts/execution/{sid}_reply.md'), encoding='utf-8').read()
    blocks = re.findall(r'```r\n(.*?)```', rep, re.S)
    if len(blocks) != 1: raise SystemExit(f'FAIL {sid}: expected exactly one ```r block, found {len(blocks)}')
    fr = f'builds/frozen/{sid}/analysis/{sub}/main.R'; d.wx(fr, blocks[0]); os.chmod(d.p(fr), 0o444)
    if d.sha(fr) != d.sha(f'analysis/{sub}/main.R'): raise SystemExit(f'FAIL {sid}: extracted code differs from installed analysis/{sub}/main.R')
    print(sid, 'frozen', d.sha(fr)[:12], '== installed')
FZ = ['artifacts/stage3_locked_design.json'] + [f'builds/frozen/{s}/analysis/{v[2]}/main.R' for s, v in B.items()]
# Structural reviews are sent by drive_s4b.py with the snapshot of the mechanical report attached (not before it exists).
R = d.root
for cmd in [['validation/source_verify.R', R], ['analysis/r_a/main.R', 'data/fixture_8row.csv', 'outputs/r_a'], ['analysis/r_b/main.R', 'data/fixture_8row.csv', 'outputs/r_b'],
            ['validation/compare_keyed.R', R], ['validation/run_fixtures.R', R], ['validation/check_methodology.R', R],
            ['validation/check_lineage_v2.R', R, 'S4-RA1', 'S4-RB1'], ['validation/structural_review_v2.R', R]]:
    r = d.run([RS, '--vanilla', *cmd], ok=(0, 1, 2, 3)); print('RUN', cmd[0], 'exit', r.returncode)
