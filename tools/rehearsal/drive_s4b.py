# Stage 4 part B: snapshot the NEEDS_REVIEW structural report, flag reviews, dispositions, rerun structural. Usage: drive_s4b.py ROOT GATE PREFIX
import sys, os, json, time
sys.path.insert(0, os.path.dirname(__file__)); from drive_common import *
root, gate, PFX = sys.argv[1:4]; d = D(root, gate); R = d.root
snap = d.run([PY, f'{d.G}/tools/scope_refs.py', 'snapshot', R, 'outputs/verification/structural.json', '--name', 'structural_needs_review']).stdout.strip()
keys = d.J(snap)['similarity_flags']['keys']
FZ = ['artifacts/stage3_locked_design.json', 'builds/frozen/S4-RA1/analysis/r_a/main.R', 'builds/frozen/S4-RB1/analysis/r_b/main.R', snap]
ids = []
for i, ai in enumerate(['ChatGPT', 'Grok', 'DeepSeek'], 1):
    sid = f'{PFX}{i}'; ids.append(sid)
    body = 'Stand-in structural review of the attached builders and mechanical report.\n' + '\n'.join(f'FLAG {k} FLAG_ONLY: SYNTHETIC stand-in classification (generic CSV quote-parser idiom per ACC002 S4-e reviews), not a real review' for k in keys) + '\nVERDICT: STRUCTURALLY_ACCEPTABLE'
    d.send('execution', sid, ai, 'structural reviewer', 'review', f'{LAB}\nClassify every flag key in the attached structural snapshot.\n', attach=FZ, depends=['S4-RA1', 'S4-RB1'], reply_body=body)
d.run([PY, f'{d.G}/tools/structural_dispositions.py', R, snap, *ids])
os.makedirs(d.p('outputs/superseded'), exist_ok=True); os.replace(d.p('outputs/verification/structural.json'), d.p('outputs/superseded/structural_needs_review.json'))
r = d.run([RS, '--vanilla', 'validation/structural_review_v2.R', R], ok=(0, 1, 3)); print('structural rerun exit', r.returncode, d.J('outputs/verification/structural.json')['status'])
json.dump({"reviews": ids, "structural_snapshot": snap}, open(root + '_s4b.json', 'w'))
