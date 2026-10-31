# SYNTHETIC rehearsal: Stage 4 close.  ROOT GATE  (after compose_stage4.py phases 1-3)
import sys, json; sys.path.insert(0, '/workspace/reh'); from drive_common import *
d = D(sys.argv[1], sys.argv[2])
d.run([PY, f'{d.G}/tools/scope_refs.py', 'guard', d.root, 'artifacts/stage4_validation_status.json'] + [f'receipts/{r}.json' for r in ['source','fixtures','reconciliation','structural','validation','lineage','methodology','stage3_lock']])
d.owner('execution', 'Stage 4 sign-off and Validation Gate acceptance')
d.ledger('execution', [('all seven Stage 4 receipts PASS', 'artifacts/stage4_validation_status.json'), ('verify_run ACCEPT', 'outputs/verification/verdict.csv'),
                       ('structural flags disposed unanimously', 'outputs/verification/structural_dispositions.json')], extra_scopes=('validation_gate', 'structural_review'))
res, p, n = d.complete('execution')
json.dump({"complete_execution": [res.get('status'), p, n]}, open(d.root + '_s4c.json', 'w')); sys.exit(0 if res.get('status') == 'PASS' and p == n else 1)
