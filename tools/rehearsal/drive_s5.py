# SYNTHETIC rehearsal: Stage 5 (finish) and final certification.  Usage: drive_s5.py ROOT GATE   (after drive_s4c.py)
import sys, os, json, csv, time; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from drive_common import *
d = D(sys.argv[1], sys.argv[2]); R = d.root
s3 = d.J('artifacts/stage3_locked_design.json')['methodology']
if not os.environ.get('REH_RESUME_S5'): d.gate('begin', 'finish')  # resume skips an already-begun stage
tot = list(csv.DictReader(open(d.p('outputs/r_a/totals.csv'))))[0]; rows = list(csv.DictReader(open(d.p('outputs/r_a/rank_rows.csv'))))
qual = sorted(r['id'] for r in rows); sel = [r['id'] for r in sorted(rows, key=lambda r: int(r['rank_n'])) if r['place_state'] == 'SELECTED']
c1 = f"Qualifying records {', '.join(qual)} (n={tot['qualified_n']}); selected {', '.join(sel)} (n={tot['selected_n']}); selected sum {tot['selected_sum']} (RES-totals, RES-rank_rows)"
c2 = 'ACCEPT mechanical conformity of this synthetic run; no business action is authorized (RES-build_report)'
DL = 'docs/stage5/interpretation.md'
_t = f'# {LAB}\n\nC1 (descriptive): {c1}.\n\nC2 (recommendation): {c2}.\n'
if not (os.environ.get('REH_RESUME_S5') and os.path.exists(d.p(DL)) and open(d.p(DL), encoding='utf-8').read() == _t): d.wx(DL, f'# {LAB}\n\nC1 (descriptive): {c1}.\n\nC2 (recommendation): {c2}.\n')
AT = [DL, 'artifacts/stage4_validation_status.json', 'outputs/r_a/totals.csv', 'outputs/r_a/rank_rows.csv']
roles = [('S5-i1', 'ChatGPT', 'interpreter'), ('S5-r1', 'DeepSeek', 'inference_reviewer'), ('S5-n1', 'Grok', 'numerical_auditor')]
rp = {sid: (f'transcripts/finish/{sid}_reply.md' if os.path.exists(d.p(f'transcripts/finish/{sid}_reply.md')) else d.send('finish', sid, ai, role, 'review', f'Stage 5 {role} first pass. Review the attached interpretation against the attached outputs. End with VERDICT.', AT)) for sid, ai, role in roles}
rp['S5-x1'] = d.send('finish', 'S5-x1', 'ChatGPT', 'cross_review', 'review', 'Stage 5 cross review of the three frozen first passes. End with VERDICT.', AT + [rp[s] for s, _, _ in roles], depends=[s for s, _, _ in roles])
cov = d.wx('docs/stage5/claim_coverage.json', dict(status='PASS', claims=['C1', 'C2'], evidence=d.ref(rp['S5-x1']), synthetic=LAB))
rev = d.wx('docs/stage5/revision.json', dict(status='UNCHANGED', unresolved_flags=0, synthetic=LAB))
oc = d.wx('docs/stage5/outcome_contract.json', s3['outcome_contract'])
D_ = d.ref(DL)
common = dict(target_id=s3['analytical_target']['id'], warrant='Exact oracle/fixture agreement (SYNTHETIC)', contrary_evidence='none found (SYNTHETIC)', defeater='a fixture mismatch',
   uncertainty='none beyond synthetic scope', scope='frozen synthetic CSV only', sensitivity='not applicable', reviewer='inference_reviewer', disposition='accepted',
   numerical_audit='PASS', inference_review='PASS', unresolved_objections=0, review_evidence=d.ref(rp['S5-r1']), deliverable=D_)
claims = [dict(id='C1', type='descriptive', wording=c1, result_ids=['RES-totals', 'RES-rank_rows'], premise_ids=['P01'], **common),
          dict(id='C2', type='recommendation', wording=c2, result_ids=['RES-build_report'], premise_ids=[], owner_tradeoff='none (synthetic)', action='ACCEPT',
               evidence_tag='verified', tag_assigned_by='coordinator', **common)]
prov = []
for sid, ai, role in roles:
    e = d.J(f'artifacts/operations/finish_sends/{sid}.json')
    prov.append(dict(role=role, provider=ai, model='UNVERIFIED (SYNTHETIC)', session='SYNTHETIC', settings='SYNTHETIC', seeds='not exposed', context_disclosure='SYNTHETIC packet only',
        first_pass_frozen_at=e['captured_at_utc'], peer_access='none_before_freeze', contamination='none (SYNTHETIC)', coordinator_draft_seen=True,
        input=d.ref(f'packets/finish/{sid}/message.md'), output=d.ref(rp[sid])))
rc = dict(stage=5, status='PASS', synthetic=LAB, workflow_gate_report_sha256=d.sha('artifacts/workflow_gate_status.json'), ai1_first_pass='PASS', ai2_first_pass='PASS', ai3_first_pass='PASS',
   information_barrier='PASS', cross_review='PASS', finish_gates='PASS', human_analyst_approval='APPROVED', unresolved_issues=0, deliverables=[DL],
   substantive_claim_ids=['C1', 'C2'], claim_ledger=claims, claim_coverage_review=dict(status='PASS', report=cov), revision=dict(status='UNCHANGED', unresolved_flags=0, report=rev),
   assurance=dict(computation='verified', inference='adequate', decision='act', outcome_evaluation='pending'),
   outcome_followup=dict(run_id=s3['outcome_contract']['followup_run_id'], owner=s3['outcome_contract']['owner'], contract=oc), ai_provenance=prov)
d.wx('artifacts/stage5_interpretation_status.json', rc)
d.owner('finish', 'Stage 5 sign-off and final certification')
d.ledger('finish', [('three first passes and cross review PASS', rp['S5-x1']), ('Stage 5 receipt composed', 'artifacts/stage5_interpretation_status.json')], extra_scopes=('final_certification',))
res, p, n = d.complete('finish'); out = {"complete_finish": [res.get('status'), p, n]}
if res.get('status') == 'PASS':
    r = d.gate('finalize', ok=(0, 1)); c = d.J('artifacts/final_certificate.json')
    out['finalize'] = [c.get('result'), c.get('certified')]; print('finalize:', out['finalize'])
    if not c.get('certified'): [print('   FAIL', x['check'], '|', str(x.get('detail'))[:200]) for x in c.get('checks', []) if x.get('result') != 'PASS']
json.dump(out, open(R + '_s5.json', 'w')); sys.exit(0 if out.get('finalize', [None, False])[1] else 1)
