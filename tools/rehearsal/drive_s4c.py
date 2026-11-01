# SYNTHETIC rehearsal: Stage 4 close.  Usage: drive_s4c.py ROOT GATE   (after drive_s4b.py)
# compose phase 1 -> versioned_reports -> verify_run first pass (archived) -> rebuild_env -> phase 2 -> verify_run second pass -> phase 3
# -> guard -> owner -> ledger -> complete execution.
import sys, os, json, shutil; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from drive_common import *
d = D(sys.argv[1], sys.argv[2]); R = d.root; C = [PY, f'{d.G}/tools/compose_stage4.py', R]
d.run(C + ['1'])
d.run([RS, '--vanilla', 'validation/versioned_reports.R', R])
P = 'outputs/verification/runs/verify_run_pass1'; os.makedirs(d.p(P))
r = d.run([RS, '--vanilla', 'validation/verify_run.R', R], ok=(0, 1)); d.wx(f'{P}/console.txt', r.stdout + r.stderr)
for f in ['checks.csv', 'verdict.csv', 'module_decision_uncertainty.json']: shutil.copy(d.p(f'outputs/verification/{f}'), d.p(f'{P}/{f}'))
for f in os.listdir(d.p(P)): os.chmod(d.p(f'{P}/{f}'), 0o444)
d.run([RS, '--vanilla', 'environment/rebuild_env.R', R])
d.run(C + ['2'])
r = d.run([RS, '--vanilla', 'validation/verify_run.R', R]); print(r.stdout.strip().splitlines()[-1])
d.run(C + ['3'])
d.run([PY, f'{d.G}/tools/scope_refs.py', 'guard', R, 'artifacts/stage4_validation_status.json'] + [f'receipts/{x}.json' for x in ['source','fixtures','reconciliation','structural','validation','lineage','methodology','stage3_lock']])
d.owner('execution', 'Stage 4 sign-off and Validation Gate acceptance')
d.ledger('execution', [('all seven Stage 4 receipts PASS', 'artifacts/stage4_validation_status.json'), ('verify_run ACCEPT', 'outputs/verification/verdict.csv'),
                       ('structural flags disposed unanimously', 'outputs/verification/structural_dispositions.json')], extra_scopes=('validation_gate', 'structural_review'))
res, p, n = d.complete('execution')
json.dump({"complete_execution": [res.get('status'), p, n]}, open(R + '_s4c.json', 'w')); sys.exit(0 if res.get('status') == 'PASS' and p == n else 1)
