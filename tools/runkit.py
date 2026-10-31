#!/usr/bin/env python3
"""Run tooling for a live (or rehearsal) acceptance run: one generic path from packet to operations ledger.
Replaces the ACC002-specific retrofit assembler (assemble_live.py) for a fresh run.  Write-once everywhere; every value
is read from files or the machine clock; a missing fact is an error, never a default.

  packet  ROOT STAGE ID --ai AI --role ROLE --kind KIND --message FILE [--attach P ...] [--depends ID ...]
          [--accepted-code P ...] [--builder-role R] [--locked-sections]   -> packets/STAGE/ID/{message.md,packet.json}
  capture ROOT STAGE ID REPLY_FILE   (REPLY_FILE = bytes from the chat's Copy button; END_REPLY marker required)
  ledger  ROOT STAGE  -> artifacts/operations/STAGE.json  (the stage's captured sends; nothing else)
Audit-only records were cut (owner approval t1660u, docs/CHANGES_FROM_ABLATIONS.md): no dispatch/"sent" record, no
ready/sent/verified chronology, no binding file, no approvals/conditions/deviations/revocations/transcript index in the
ledger.  What stays is what keeps each reply tied to the right packet: nonce, END_REPLY marker, exact reply bytes, the
capture record, role, packet and attachment hashes.
"""
import json, hashlib, os, sys, secrets, datetime, argparse, re
def now(): return datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
def sha(p): return hashlib.sha256(open(p, 'rb').read()).hexdigest()
class K:
    def __init__(s, root): s.root = os.path.abspath(root)
    def p(s, rel): return os.path.join(s.root, rel)
    def ref(s, rel):
        if not os.path.isfile(s.p(rel)): sys.exit(f'FAIL missing {rel}')
        return {"path": rel, "sha256": sha(s.p(rel))}
    def J(s, rel): return json.load(open(s.p(rel), encoding='utf-8-sig'))
    def wx(s, rel, obj):
        os.makedirs(os.path.dirname(s.p(rel)), exist_ok=True)
        data = obj if isinstance(obj, bytes) else obj.encode() if isinstance(obj, str) else (json.dumps(obj, indent=1, ensure_ascii=False) + '\n').encode()
        with open(s.p(rel), 'xb') as f: f.write(data)
        os.chmod(s.p(rel), 0o444); return s.ref(rel)
    def state(s): return s.J('artifacts/procedure/run_state.json')
# Naming convention (owner card t1636s6840): run tooling never produces a path that the ref-scope guard reads as historical.
HIST = re.compile(r'(^|/)(runs|versioned|sandbox|superseded|failed_attempts)(/|$)|attempt|pass\d(/|$)', re.I)
def safe(name, what):
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', name or '') or HIST.search(name): sys.exit(f'FAIL {what} {name!r}: use [A-Za-z0-9._-] and never attempt/pass<N>/runs/versioned/sandbox/superseded')
    return name
# Plan A (owner card t1674s7005): the packet refuses a role the stage does not allow and a send with no attachment other than
# the stage receipt.  REVIEW_ROLES is a copy of contracts.R m_stage_ai_roles (kept in sync by tools/tests/test_runkit.py);
# EXTRA_ROLES are the other roles a stage sends (cross_review everywhere; start decision_drafter; design lock_review;
# execution builders and the structural reviewer), as in the REH-F5B rehearsal ledgers.
REVIEW_ROLES = {'start': ['independent_reconstruction', 'red_team'], 'framing': ['framing_builder', 'decision_fit_review', 'framing_red_team'],
                'design': ['designer_a', 'designer_b', 'risk_reviewer'], 'finish': ['interpreter', 'inference_reviewer', 'numerical_auditor']}
EXTRA_ROLES = {'start': ['decision_drafter', 'cross_review'], 'framing': ['cross_review'], 'design': ['lock_review', 'cross_review'],
               'execution': ['builder R-A', 'builder R-B', 'structural reviewer', 'cross_review'], 'finish': ['cross_review']}
def allowed_roles(stage): return REVIEW_ROLES.get(stage, []) + EXTRA_ROLES.get(stage, [])
STAGE_RECEIPTS = {'start': 'artifacts/stage1_decision.json', 'framing': 'artifacts/stage2_framing.json', 'design': 'artifacts/stage3_locked_design.json',
                  'execution': 'artifacts/stage4_validation_status.json', 'finish': 'artifacts/stage5_interpretation_status.json'}
def frag(stage, sid): return f'artifacts/operations/{stage}_sends/{sid}.json'
def main():
    a = argparse.ArgumentParser(); a.add_argument('cmd'); a.add_argument('root'); a.add_argument('stage'); a.add_argument('id', nargs='?'); a.add_argument('file', nargs='?')
    for o in ['ai', 'role', 'kind', 'message', 'builder_role', 'synthetic']: a.add_argument('--' + o.replace('_', '-'), dest=o)
    a.add_argument('--attach', nargs='*', default=[]); a.add_argument('--depends', nargs='*', default=[])
    a.add_argument('--accepted-code', nargs='*', default=None); a.add_argument('--locked-sections', action='store_true')
    x = a.parse_args(); safe(x.stage, 'stage')
    if x.id and x.cmd != 'ledger': safe(x.id, 'send id')
    k = K(x.root); st = k.state(); run = st['run_id']
    if x.cmd == 'packet':
        if st.get('current_step') != x.stage: sys.exit(f'FAIL stage {x.stage} is not the authorized current step')
        if x.role not in allowed_roles(x.stage): sys.exit(f'FAIL role {x.role!r} is not allowed at {x.stage}: {allowed_roles(x.stage)}')
        if not [f for f in x.attach if os.path.normpath(f).replace(os.sep, '/') != STAGE_RECEIPTS.get(x.stage)]: sys.exit(f'FAIL packet needs at least one --attach other than the stage receipt')
        nonce = secrets.token_hex(8); marker = f'END_REPLY {x.id} {nonce}'
        body = open(x.message, encoding='utf-8').read().rstrip('\n') + f'\n\nEnd your reply with this exact final line:\n{marker}\n'
        msg = k.wx(f'packets/{x.stage}/{x.id}/message.md', body)
        P = {"run_id": run, "stage": x.stage, "send_id": x.id, "nonce": nonce, "end_marker": marker,
             "target_ai": x.ai, "role": x.role, "send_kind": x.kind, "message": msg, "attachments": [k.ref(f) for f in x.attach],
             "depends_on": x.depends}
        if x.synthetic: P['synthetic'] = x.synthetic
        if x.builder_role: P['builder_role'] = x.builder_role
        if x.accepted_code is not None: P['accepted_code'] = [k.ref(f) for f in x.accepted_code]
        if x.locked_sections:
            m = k.J('artifacts/stage3_locked_design.json')['methodology']
            P.update(output_rules=m['operational']['output_rules'], checkpoint_output_rules=m['operational']['checkpoint_output_rules'], checkpoints=m['checkpoints'], receipt_dependencies=m['receipt_dependencies'])
        print(k.wx(f'packets/{x.stage}/{x.id}/packet.json', P)['sha256'], marker)
    elif x.cmd == 'capture':
        pk = k.J(f'packets/{x.stage}/{x.id}/packet.json'); b = open(x.file, 'rb').read(); t = now()
        lines = b.decode('utf-8').rstrip('\r\n').splitlines()
        if not lines or lines[-1].strip() != pk['end_marker']: sys.exit(f'FAIL reply does not end with {pk["end_marker"]} (recapture; do not edit the reply)')
        rp = k.wx(f'transcripts/{x.stage}/{x.id}_reply.md', b)
        cp = k.wx(f'captures/{x.stage}/{x.id}_capture.json', {"send_id": x.id, "nonce": pk['nonce'], "packet": k.ref(f'packets/{x.stage}/{x.id}/packet.json'), "reply": rp, "capture_sha256": rp['sha256']})
        e = {"id": x.id, "ai": pk['target_ai'], "role": pk.get('role'), "send_kind": pk['send_kind'], "nonce": pk['nonce'], "packet": k.ref(f'packets/{x.stage}/{x.id}/packet.json'), "attachments": pk['attachments'],
             "reply": rp, "capture": cp, "captured_at_utc": t, "depends_on": pk['depends_on']}
        if pk.get('builder_role'): e['builder_role'] = pk['builder_role']
        k.wx(frag(x.stage, x.id), e); print('captured', rp['sha256'][:16])
    elif x.cmd == 'ledger':
        if st.get('current_step') != x.stage: sys.exit(f'FAIL stage {x.stage} not current')
        d = k.p(f'artifacts/operations/{x.stage}_sends'); sends = [json.load(open(os.path.join(d, f))) for f in sorted(os.listdir(d))] if os.path.isdir(d) else []
        if not sends: sys.exit('FAIL no captured sends')
        sends.sort(key=lambda e: (e['captured_at_utc'], e['id']))
        o = {"version": "acceptance-v2", "run_id": run, "stage": x.stage, "sends": sends, "tool": "tools/runkit.py"}
        if x.synthetic: o['synthetic'] = x.synthetic
        print(k.wx(f'artifacts/operations/{x.stage}.json', o)['sha256'])
    else: sys.exit('unknown command')
if __name__ == '__main__': main()
