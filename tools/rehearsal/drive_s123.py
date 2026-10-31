# Stages 1-3 of the SYNTHETIC rehearsal. Usage: drive_s123.py ROOT GATE RUN_ID ACC002_ROOT
import sys, os, json, shutil, time
sys.path.insert(0, os.path.dirname(__file__)); from drive_common import *
root, gate, RUN, SRC = sys.argv[1:5]; d = D(root, gate); res = {}
os.makedirs(root)
for x in ['data', 'analysis', 'validation', 'environment']: shutil.copytree(f'{SRC}/{x}', d.p(x))
for _h in ['structural_review_v2.R', 'versioned_reports.R']: os.chmod(d.p(f'validation/{_h}'), 0o644)  # source copy may be read-only
shutil.copy(f'{d.G}/tools/rehearsal/harness/structural_review_v2.R', d.p('validation/structural_review_v2.R'))  # owner card t1637s6856
shutil.copy(f'{d.G}/tools/rehearsal/harness/versioned_reports.R', d.p('validation/versioned_reports.R'))  # owner card t1638s6865
import subprocess; subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'box_manifest.py'), d.root], check=True)
for x in ['stage1', 'stage2', 'stage3']: shutil.copytree(f'{SRC}/docs/{x}', d.p(f'docs/{x}'))
d.wx('SYNTHETIC_REHEARSAL.txt', LAB + f'\nRun {RUN}. Content (data, accepted analysis code, validation tools, design text) copied from ACC002; every AI reply and owner record is SYNTHETIC.\n')
d.gate('start', RUN)
A = lambda k: json.load(open(f'{SRC}/artifacts/{k}', encoding='utf-8-sig'))
def stage(step, plan, receipt_fn, conds_fn):
    d.gate('begin', step); rp = {}
    for sid, ai, role, deps, att, body in plan: rp[sid] = d.send(step, sid, ai, role, 'review', f'{LAB}\nStage {step}, role {role}.\n', attach=att, depends=deps, reply_body=body)
    rc = receipt_fn(rp); d.wx(f'artifacts/{rc[0]}', rc[1]); d.owner(step, f'sign-off of {step}')
    d.ledger(step, conds_fn(rp, rc[0])); res[step] = d.complete(step)[1:]
# Stage 1
s1 = A('stage1_decision.json')
keep1 = ['stage','status','decision_id','decision_statement','decision_owner','frozen_question','ai2_independent_reconstruction','ai3_independent_red_team','start_gate','stakeholder_confirmation','human_analyst_approval','unresolved_issues']
def r1(rp):
    o = {k: s1[k] for k in keep1}; o.update(synthetic=LAB, reviewer_verdicts={k: 'PASS (SYNTHETIC stand-in)' for k in rp},
        evidence=dict(start_record=d.ref('docs/stage1/START_RECORD.md'), fixture=d.ref('data/fixture_8row.csv'), ai1_reply=d.ref(rp['S1-01']), ai2_reply=d.ref(rp['S1-02']), ai3_reply=d.ref(rp['S1-03'])))
    return 'stage1_decision.json', o
F = ['data/fixture_8row.csv', 'docs/stage1/START_RECORD.md']
stage('start', [('S1-01','ChatGPT','decision_drafter',[],F,None), ('S1-02','Grok','independent_reconstruction',['S1-01'],F,None), ('S1-03','DeepSeek','red_team',['S1-01'],F,None)], r1,
      lambda rp, a: [('Stage 1 receipt composed from the captured replies', f'artifacts/{a}'), ('AI2 reconstruction PASS', rp['S1-02']), ('AI3 red team PASS', rp['S1-03'])])
# Stage 2
s2 = A('stage2_framing.json')
keep2 = ['stage','status','question_id','question_type','analytical_question','capacity_stance','capacity_unit','ai1_builder','ai2_decision_fit_review','ai3_framing_red_team','cross_review','framing_gate','stakeholder_approval','human_analyst_approval','unresolved_issues']
def r2(rp):
    o = {k: s2[k] for k in keep2 if k in s2}; o.update(synthetic=LAB, reviewer_verdicts={k: 'PASS (SYNTHETIC stand-in)' for k in rp},
        evidence=dict(stage1_decision=d.ref('artifacts/stage1_decision.json'), replies=[d.ref(v) for v in rp.values()]))
    return 'stage2_framing.json', o
F2 = ['artifacts/stage1_decision.json', 'data/fixture_8row.csv']
stage('framing', [('S2-01','ChatGPT','framing_builder',[],F2,None), ('S2-02','Grok','decision_fit_review',['S2-01'],F2,None), ('S2-03','DeepSeek','framing_red_team',['S2-01'],F2,None),
      ('S2-04','ChatGPT','cross_review',['S2-01','S2-02','S2-03'],F2,None)], r2, lambda rp, a: [('Stage 2 receipt composed from captured replies', f'artifacts/{a}'), ('cross review PASS', rp['S2-04'])])
# Stage 3: design text reused unchanged; provenance and evidence are the new sends
s3 = A('stage3_locked_design.json')
DT = ['artifacts/stage2_framing.json', 'docs/stage3/DESIGN_GATE_RECORD.md', 'validation/fixtures/manifest.json', 'validation/fixtures/oracle.json']
def r3(rp):
    o = {k: v for k, v in s3.items() if k not in ('evidence', 'ai_provenance')}; o['synthetic'] = LAB
    prov = []
    for sid, role, ai in [('D-01','designer_a','ChatGPT'),('D-02','designer_b','Grok'),('D-03','risk_reviewer','DeepSeek')]:
        e = d.J(f'artifacts/operations/design_sends/{sid}.json')
        prov.append(dict(role=role, provider=ai, model='UNVERIFIED (SYNTHETIC)', session='SYNTHETIC', settings='SYNTHETIC', seeds='not exposed', context_disclosure='SYNTHETIC packet only',
             first_pass_frozen_at=e['captured_at_utc'], peer_access='none_before_freeze', contamination='none (SYNTHETIC)', coordinator_draft_seen=False,
             input=d.ref(f'packets/design/{sid}/message.md'), output=d.ref(rp[sid])))
    o['ai_provenance'] = prov
    o['evidence'] = dict(design_gate_record=d.ref('docs/stage3/DESIGN_GATE_RECORD.md'), fixtures_manifest=d.ref('validation/fixtures/manifest.json'), fixtures_oracle=d.ref('validation/fixtures/oracle.json'),
        first_pass_replies=[d.ref(rp[k]) for k in ['D-01','D-02','D-03']], cross_review=d.ref(rp['D-04']), lock_review=d.ref(rp['D-05']),
        stage1_decision=d.ref('artifacts/stage1_decision.json'), stage2_framing=d.ref('artifacts/stage2_framing.json'), owner_record=d.ref('approvals/SYNTHETIC_owner_design_lock.md'))
    return 'stage3_locked_design.json', o
d.owner('design_lock', 'lock of the reused ACC002 design text')
stage('design', [('D-01','ChatGPT','designer_a',[],DT,None), ('D-02','Grok','designer_b',[],DT,None), ('D-03','DeepSeek','risk_reviewer',[],DT,None),
      ('D-04','ChatGPT','cross_review',['D-01','D-02','D-03'],DT,None), ('D-05','Grok','lock_review',['D-04'],DT,None)], r3,
      lambda rp, a: [('Stage 3 lock composed from the reused design text and captured replies', f'artifacts/{a}'), ('lock review PASS', rp['D-05'])])
json.dump(res, open(root + '_s123.json', 'w')); print(res)
