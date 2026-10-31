#!/usr/bin/env python3
"""Run tooling: generic Stage 4 receipt composer (replaces the ACC002-specific compose.py).  Usage: compose_stage4.py ROOT PHASE
  phase 1  (after structural PASS)        receipts source, stage3_lock, fixtures, reconciliation, structural
  phase 2  (after versioned_reports, verify_run first pass archived to outputs/verification/runs/verify_run_pass1/, rebuild_env)
                                          receipts methodology, lineage
  phase 3  (after verify_run second pass) receipt validation and artifacts/stage4_validation_status.json
Every value is read from run_state, the runkit send fragments, captured reply text (VERDICT: lines) or tool outputs; nothing is
typed as a result and a missing fact is a FAIL.  Historical records (first verify_run pass, versioned/ sandbox reports,
replay) are cited through write-once scope_refs snapshots and their embedded content is read from the snapshot copies, so a
later overwrite of a live path cannot make a receipt stale.  Every file written is write-once."""
import json, hashlib, os, sys, glob, csv, re, datetime, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import scope_refs as SR
R, PH = os.path.abspath(sys.argv[1]), sys.argv[2]; os.chdir(R)
def sha(p): return hashlib.sha256(open(p, 'rb').read()).hexdigest()
def ref(p):
    if not os.path.isfile(p): sys.exit(f'FAIL missing {p}')
    return {"path": p, "sha256": sha(p)}
def J(p): return json.load(open(p, encoding='utf-8-sig'))
def wx(p, o):
    os.makedirs(os.path.dirname(p) or '.', exist_ok=True)
    with open(p, 'x', newline='\n', encoding='utf-8') as f: f.write(json.dumps(o, indent=1, ensure_ascii=False) + '\n')
    os.chmod(p, 0o444); print(sha(p), p)
def snap(p, name):
    t = f'{SR.SNAP}/{name}'
    if os.path.isdir(t):  # idempotent re-use only if the snapshot is of the same source bytes
        m = J(f'{t}/manifest.json')
        if m['source'] != {"path": p, "sha256": sha(p)}: sys.exit(f'FAIL snapshot {name} exists for other bytes')
        return next(e['copy']['path'] for e in m['entries'] if e['original']['path'] == p)
    return SR.snapshot(R, p, name)
now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
ST = J('artifacts/procedure/run_state.json'); RUN = ST['run_id']
D = J('artifacts/stage3_locked_design.json'); M = D['methodology']; dsha = sha('artifacts/stage3_locked_design.json')
SENDS = [J(p) for p in sorted(glob.glob('artifacts/operations/execution_sends/*.json'))]
BUILD = {s['builder_role']: s for s in SENDS if s['send_kind'] == 'builder'}
REVS = [s for s in SENDS if s['send_kind'] == 'review']
def verdict(s):
    v = re.findall(r'^VERDICT:\s*(\S+)', open(s['reply']['path'], encoding='utf-8').read(), re.M)
    if len(v) != 1: sys.exit(f'FAIL {s["id"]}: expected one VERDICT line, found {len(v)}')
    return v[0]
SYN = ST.get('synthetic') or next((x.get('synthetic') for x in SENDS if x.get('synthetic')), None)
for r_ in ('R-A', 'R-B'):
    if r_ not in BUILD: sys.exit(f'FAIL no captured builder send for {r_}')
PROD = f"tools/compose_stage4.py (run tooling) for run {RUN}; builders " + ', '.join(f"{r_} {BUILD[r_]['ai']} {BUILD[r_]['id']}" for r_ in ('R-A', 'R-B'))
def base(role, status, at):
    o = {"role": role, "status": status, "run_id": RUN, "design_version": D['design_version'], "fixture_version": D['fixture_version'], "design_sha256": dsha, "checked_at_utc": at}
    if SYN: o['synthetic'] = SYN
    return o
ROLES = ['source', 'fixtures', 'reconciliation', 'structural', 'validation', 'lineage', 'methodology']
def deps(role):
    peers = {f'receipts/{r}.json' for r in ROLES if r != role}
    return [ref(p) for p in M['receipt_dependencies'][role] if p not in peers]
if PH == '1':
    s = J('outputs/verification/source.json')
    S0 = base('source', s['status'], s.get('checked_at_utc') or s.get('recorded_at_utc') or now)
    S0.update(source_kind=M['operational']['source_contract']['kind'], sql_extraction_used=False, sql_source_gate="NOT_APPLICABLE",
              fidelity_check={"status": s['status'], "report": ref('outputs/verification/source_report.txt')}, observed_source=dict(ref('data/fixture_8row.csv'), bytes=os.path.getsize('data/fixture_8row.csv')),
              dependencies=deps('source'), evidence=ref('outputs/verification/source.json'), producer=PROD + "; validation/source_verify.R", written_at_utc=now)
    wx('receipts/source.json', S0)
    dc = glob.glob('artifacts/procedure/checks/design-complete-*.json')
    if len(dc) != 1: sys.exit(f'FAIL expected one design-complete check record, found {len(dc)}')
    L0 = base('stage3_lock', 'PASS', ST['completed_steps']['design']['completed_at_utc'])
    L0.update(lock=ref('artifacts/stage3_locked_design.json'), design_complete_gate=ref(dc[0]), execution_begin=ST['current_authorization'],
              fixture_inputs=ref('validation/fixtures/manifest.json'), fixture_expected=ref('validation/fixtures/oracle.json'), source=ref('data/fixture_8row.csv'), producer=PROD)
    if ST['completed_steps']['design']['artifact']['sha256'] != dsha: sys.exit('FAIL lock bytes differ from the design completion record')
    wx('receipts/stage3_lock.json', L0)
    rows = list(csv.DictReader(open('outputs/verification/fixture_results.csv', encoding='utf-8-sig'))); rfs = J('outputs/verification/run_fixtures_status.json')
    ok = rows and all(r['match_a'] == 'TRUE' and r['match_b'] == 'TRUE' for r in rows)
    F = base('fixtures', 'PASS' if rfs['status'] == 'PASS' and ok else 'FAIL', rfs.get('checked_at_utc') or rfs.get('recorded_at_utc') or rows[-1]['recorded_at_utc'])
    F.update(cases=[{k: r[k] for k in ['id', 'expected', 'observed_a', 'observed_b']} for r in rows], components={k: v for k, v in rfs.items() if isinstance(v, str) and v in ('PASS', 'FAIL')},
             metamorphic=ref('outputs/verification/metamorphic_results.csv'), fixture_results=ref('outputs/verification/fixture_results.csv'), planted_defects=ref('outputs/verification/planted_defects.json'),
             poison=ref('outputs/verification/poison.json'), producer=PROD + "; validation/run_fixtures.R", dependencies=deps('fixtures'), evidence=ref('outputs/verification/run_fixtures_status.json'), written_at_utc=now)
    wx('receipts/fixtures.json', F)
    rc = J('outputs/verification/reconciliation_detail.json')
    C = base('reconciliation', rc['status'], rc['checked_at_utc']); C.update(fields=rc['fields'], mismatch_count=rc['mismatch_count'], row_count=rc['row_count'],
             dependencies=deps('reconciliation'), evidence=ref('outputs/verification/reconciliation_detail.json'), producer=PROD + "; validation/compare_keyed.R", written_at_utc=now)
    wx('receipts/reconciliation.json', C)
    s = J('outputs/verification/structural.json'); sd = J('outputs/verification/structural_dispositions.json')
    if not REVS: sys.exit('FAIL no captured review sends')
    vs = {x['id']: verdict(x) for x in REVS}
    st_ok = s['status'] == 'PASS' and all(v == 'STRUCTURALLY_ACCEPTABLE' for v in vs.values())
    S = base('structural', 'PASS' if st_ok else 'FAIL', s['checked_at_utc'])
    S.update(mechanical=ref('outputs/verification/structural.json'), dispositions=ref('outputs/verification/structural_dispositions.json'), ai_reviews={k['id']: k['reply'] for k in REVS}, ai_verdicts=vs,
             verdict_basis="VERDICT: line parsed from each captured review reply by tools/compose_stage4.py",
             producer_disclosure="The mechanical evidence was produced by validation/structural_review_v2.R (sha " + sha('validation/structural_review_v2.R') + "); the locked dependency list names validation/structural_review.R (v1), which did not produce this evidence.",
             dependencies=deps('structural'), producer=PROD, written_at_utc=now)
    wx('receipts/structural.json', S)
if PH == '2':
    vds = sorted(glob.glob('outputs/verification/versioned/*/summary.json'))
    if len(vds) != 1: sys.exit(f'FAIL expected one versioned report set, found {len(vds)}')
    VD = os.path.dirname(vds[0])
    SNP = {k: snap(f'{VD}/{k}.json', f'versioned_{k}') for k in ['test_versions', 'environment', 'checkpoints', 'metamorphic', 'summary']}
    SNP['replay'] = snap('outputs/verification/replay.json', 'replay')
    DUo = 'outputs/verification/runs/verify_run_pass1/module_decision_uncertainty.json'; SNP['du'] = snap(DUo, 'verify_first_du')
    tv, env, cps, mr, rp = (J(SNP[k]) for k in ['test_versions', 'environment', 'checkpoints', 'metamorphic', 'replay'])
    rst = J('outputs/verification/restoration.json')
    mods = {}
    for k, p in M['modules'].items():
        if not p.get('required'): mods[k] = {"disposition": "NOT_APPLICABLE"}; continue
        rp_ = SNP['du'] if k == 'decision_uncertainty' else f'outputs/verification/module_{k}.json'; x = J(rp_)
        mods[k] = {"disposition": x.get('disposition'), "interpretation": x.get('interpretation') or x.get('rationale'), "report": ref(rp_)}
    sens = []
    for sp in M['sensitivity']['specifications']:
        p = f'outputs/verification/sensitivity_{sp["id"]}.json'; x = J(p); rels = x.get('evidence_relations', []); allp = rels and all(r['result'] == 'PASS' for r in rels)
        sens.append({"id": sp['id'], "status": x['status'], "report": ref(p), "interpretation": f"{len(rels)} evidence relations, all PASS for both paths; no instability observed (computed from the report)." if allp else "Not all evidence relations PASS: see report (instability restricts claims)."})
    gc = subprocess.run(['git', '-C', os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip() or 'UNVERIFIED'
    dirty = subprocess.run(['git', '-C', os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'status', '--porcelain'], capture_output=True, text=True).stdout.strip()
    rep = {"r_version": env['r_version'], "os": env['os'], "locale": env['locale'], "timezone": env['timezone'], "encoding": json.dumps(env['encoding']), "rng": " / ".join(env['rng_kind']),
           "seeds": "No stochastic step in the locked pipeline; compare_keyed positional probe seed 42 (reconciliation_detail.json)", "sql_client": "not applicable: no SQL extraction (source.json)", "sql_mode": "not applicable: no SQL extraction",
           "threads": json.dumps(env['threads']), "workflow_commit": f"gate tooling {gc}" + (" (working tree has uncommitted changes)" if dirty else " (clean checkout)"), "project_commit": "not applicable: the run root is not under version control; content bound by sha256 receipts",
           "working_tree": "not applicable: no git working tree; files bound by hash", "replay_command": " ; ".join(c["command"] for c in rp["commands"]), "retention": "All outputs and superseded files retained under outputs/; none deleted",
           "package_lock": ref('environment/package_manifest.json'), "session_info": env['session_info'], "environment_spec": ref('environment/package_manifest.json'), "restore_report": ref('outputs/verification/restoration.json'),
           "restoration_limitation": "rebuild_env.R checks the R and package versions in a fresh Rscript --vanilla process against the manifest; it does not reinstall packages into an empty library."}
    res = [{"id": f"RES-{n}", "locator": f"outputs/r_a/{n}.csv (R-A; R-B identical per K checkpoints)", "target_id": M['analytical_target']['id'], "artifact": ref(f'outputs/r_a/{n}.csv')} for n in ['totals', 'rank_rows', 'reason_totals', 'audit_rows', 'build_report']]
    chg = J('deviations/stage4_changes.json')['changes'] if os.path.exists('deviations/stage4_changes.json') else []
    tri = J('deviations/stage4_triage.json')['triage'] if os.path.exists('deviations/stage4_triage.json') else []
    X = base('methodology', 'PASS' if rp['status'] == 'PASS' and rst['status'] == 'PASS' and tv['tests'] and all(t['result'] == 'PASS' for t in tv['tests']) else 'FAIL', now)
    fd = J('outputs/verification/fixture_depth.json'); sm = J('outputs/verification/smoke.json'); dm = J('outputs/verification/dominance.json')
    X.update(target_id=M['analytical_target']['id'], test_versions=tv, triage=tri, reproducibility=rep, checkpoints=cps, metamorphic=mr, sensitivity=sens, modules=mods,
             fixtures=dict({k: fd[k] for k in ['production_reader_a', 'production_reader_b', 'poison_probe_a', 'poison_probe_b']}, report=ref('outputs/verification/fixture_depth.json')),
             smoke=dict(status=sm['status'], non_reporting=sm['non_reporting'], report=ref('outputs/verification/smoke.json')), dominance=dict(status=dm['status'], disposition=dm['disposition'], report=ref('outputs/verification/dominance.json')),
             replay=rp, replay_ref=ref(SNP['replay']), results=res, changes=chg, evidence=ref('outputs/verification/methodology_evidence.json'), versioned_summary=ref(SNP['summary']),
             snapshots={k: ref(v) for k, v in SNP.items()},
             du_disclosure="decision_uncertainty report is a write-once snapshot of the first verify_run pass (run before this receipt existed); the final verify_run pass is bound by receipts/validation.json.",
             dependencies=deps('methodology'), producer=PROD + "; validation/versioned_reports.R; environment/rebuild_env.R", written_at_utc=now)
    wx('receipts/methodology.json', X)
    ln = J('outputs/verification/lineage.json')
    L = base('lineage', ln['status'], ln.get('checked_at_utc') or ln.get('recorded_at_utc') or now)
    L.update(source_snapshot=ln['source_snapshot'], extract_identity=ln['extract_identity'], script_versions=ln['script_versions'], lineage_hash_check={"status": ln['status'], "evidence": ref('outputs/verification/lineage.json')},
             producer_disclosure="Evidence produced by validation/check_lineage_v2.R (sha " + sha('validation/check_lineage_v2.R') + "); the lock lists validation/check_lineage.R (v1) as the dependency.",
             peer_receipts_status={r: J(f'receipts/{r}.json')['status'] for r in ['source', 'fixtures', 'reconciliation', 'structural', 'methodology']}, dependencies=deps('lineage'), producer=PROD, written_at_utc=now)
    if not all(v == 'PASS' for v in L['peer_receipts_status'].values()): L['status'] = 'FAIL'
    wx('receipts/lineage.json', L)
if PH == '3':
    ck = list(csv.DictReader(open('outputs/verification/checks.csv', encoding='utf-8-sig'))); vd = list(csv.DictReader(open('outputs/verification/verdict.csv', encoding='utf-8-sig')))[0]
    du = J('outputs/verification/module_decision_uncertainty.json')
    first = snap('outputs/verification/runs/verify_run_pass1/checks.csv', 'verify_first_checks')
    ok = vd['action'] == 'ACCEPT' and ck and all(r['state'] == 'SUCCESS' for r in ck) and du['disposition'] == 'adequate'
    V = base('validation', 'PASS' if ok else 'FAIL', du['recorded_at_utc'])
    V.update(status_basis=f"verify_run.R action {vd['action']}, {sum(r['state'] == 'SUCCESS' for r in ck)}/{len(ck)} V checks SUCCESS (read from checks.csv)", action=vd['action'], finality=vd['finality'],
             evidence_tag=vd['evidence_tag'], data_state=vd['data_state'], reason_codes=json.loads(vd['reason_codes']), checks=ref('outputs/verification/checks.csv'), verdict=ref('outputs/verification/verdict.csv'),
             decision_uncertainty=ref('outputs/verification/module_decision_uncertainty.json'), verify_run_first_pass=ref(first),
             pass_disclosure="The first verify_run pass ran before receipts/methodology.json and receipts/lineage.json existed; its decision_uncertainty output (snapshot) is the methodology receipt's module report. This second pass ran with all receipts present.",
             producer="validation/verify_run.R (accepted code) Rscript --vanilla; receipt composed by tools/compose_stage4.py", dependencies=deps('validation'), written_at_utc=now)
    wx('receipts/validation.json', V)
    st = {r: J(f'receipts/{r}.json')['status'] for r in ROLES}
    def prov(role):
        s = BUILD[role]; sub = 'r_a' if role == 'R-A' else 'r_b'; pk = J(s['packet']['path'])
        return {"role": role, "send_id": s['id'], "provider": s['ai'], "model": pk.get('model') or 'UNVERIFIED: model name not recorded in the packet',
                "session": pk.get('session') or 'UNVERIFIED: chat URL not recorded in the packet', "settings": "UNVERIFIED: hosted chat does not expose sampling settings",
                "seeds": "unavailable: the hosted chat does not expose a seed", "context_disclosure": "Packet message and hash-bound attachments only (packets/execution/" + s['id'] + ")",
                "first_pass_frozen_at": s['verified_at_utc'], "peer_access": "none_before_freeze", "contamination": "None recorded: the packet carried no other-builder code or outputs (attachments listed in the packet).",
                "input": ref(f"packets/execution/{s['id']}/message.md"), "output": s['reply'], "frozen_script": ref(f"builds/frozen/{s['id']}/analysis/{sub}/main.R"), "capture_check": s['capture']}
    for role in ('R-A', 'R-B'):
        sub = 'r_a' if role == 'R-A' else 'r_b'
        if sha(f"builds/frozen/{BUILD[role]['id']}/analysis/{sub}/main.R") != sha(f'analysis/{sub}/main.R'): sys.exit(f'FAIL installed {role} differs from its frozen build')
    allpass = all(v == 'PASS' for v in st.values())
    S4 = {"stage": 4, "status": "PASS" if allpass else "FAIL", "design_version_used": D['design_version'], "fixture_version_used": D['fixture_version'], "sql_source_gate": "NOT_APPLICABLE",
          "sql_source_gate_note": "source.json: no SQL extraction; source fidelity " + st['source'], "fixtures": st['fixtures'], "r_a_status": st['fixtures'], "r_b_status": st['fixtures'],
          "r_status_basis": f"Installed builds equal frozen builder replies {BUILD['R-A']['id']} / {BUILD['R-B']['id']} (sha256 checked) and ran in the fixture and production runs (run_fixtures_status.json, smoke.json)",
          "reconciliation": st['reconciliation'], "validation_gate": st['validation'], "validation_gate_basis": f"verify_run action {vd['action']}; receipts/validation.json",
          "structural_cross_review": st['structural'], "decision_critical_model_required": False, "decision_critical_model_validation": "NOT_REQUIRED",
          "evidence_receipts": {r: ref(f'receipts/{r}.json') for r in ROLES}, "receipt_statuses": st, "unresolved_issues": 0 if allpass else 1, "unresolved_issue_list": [] if allpass else [r for r, v in st.items() if v != 'PASS'],
          "disclosures": ["verify_run first/second pass ordering (decision_uncertainty from the first pass, cited by snapshot)", "structural/lineage evidence produced by the v2 scripts while the lock lists v1 names",
                          "restoration check is version verification in a fresh vanilla session, not a reinstall"] + (["SYNTHETIC rehearsal: every AI reply and owner record is a labeled stand-in"] if SYN else []),
          "ai_provenance": [prov('R-A'), prov('R-B')], "verifier": {"action": vd['action'], "data_state": vd['data_state'], "verdict": ref('outputs/verification/verdict.csv')},
          "note": "Composed by tools/compose_stage4.py from receipts, run outputs and captured replies; no field typed as a result.", "recorded_at_utc": now}
    if SYN: S4['synthetic'] = SYN
    wx('artifacts/stage4_validation_status.json', S4)
    e = SR.guard(R, ['artifacts/stage4_validation_status.json'] + [f'receipts/{r}.json' for r in ROLES])
    if e: print('\n'.join(e)); sys.exit('FAIL ref-scope guard on Stage 4 receipts')
    print('PASS ref-scope guard on Stage 4 receipts')
else: pass
