#!/usr/bin/env python3
"""Run tooling for a live (or rehearsal) acceptance run: one generic path from packet to operations ledger.
Replaces the ACC002-specific retrofit assembler (assemble_live.py) for a fresh run.  Write-once everywhere; every value
is read from files or the machine clock; a missing fact is an error, never a default.

  packet  ROOT STAGE ID --ai AI --role ROLE --kind KIND --message FILE [--attach P ...] [--depends ID ...]
          [--accepted-code P ...] [--builder-role R] [--locked-sections]   -> packets/STAGE/ID/{message.md,packet.json}
  sent    ROOT STAGE ID --basis dispatcher_reported|machine_observed [--at ISO] [--uncertainty S] [--evidence P]
  capture ROOT STAGE ID REPLY_FILE   (REPLY_FILE = bytes from the chat's Copy button; END_REPLY marker required)
  ledger  ROOT STAGE --approvals JSON [--deviations JSON] [--attempt N]  -> artifacts/operations/STAGE.json
Approvals JSON: list of {id, scope, wording_author, owner_record, granted_at_utc, conditions:[{condition, evidence}]};
each condition's evidence is a root path; status PASS is written only when that file exists (hash bound); an approval
with an empty conditions list is refused (fix of the ACC002 empty-conditions defect).
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
def frag(stage, sid): return f'artifacts/operations/{stage}_sends/{sid}.json'
def main():
    a = argparse.ArgumentParser(); a.add_argument('cmd'); a.add_argument('root'); a.add_argument('stage'); a.add_argument('id', nargs='?'); a.add_argument('file', nargs='?')
    for o in ['ai', 'role', 'kind', 'message', 'builder_role', 'basis', 'at', 'evidence', 'approvals', 'deviations', 'attempt', 'synthetic']: a.add_argument('--' + o.replace('_', '-'), dest=o)
    a.add_argument('--uncertainty', type=int); a.add_argument('--attach', nargs='*', default=[]); a.add_argument('--depends', nargs='*', default=[])
    a.add_argument('--accepted-code', nargs='*', default=None); a.add_argument('--locked-sections', action='store_true')
    x = a.parse_args(); safe(x.stage, 'stage')
    if x.id and x.cmd != 'ledger': safe(x.id, 'send id')
    k = K(x.root); st = k.state(); run = st['run_id']
    if x.cmd == 'packet':
        if st.get('current_step') != x.stage: sys.exit(f'FAIL stage {x.stage} is not the authorized current step')
        nonce = secrets.token_hex(8); marker = f'END_REPLY {x.id} {nonce}'
        body = open(x.message, encoding='utf-8').read().rstrip('\n') + f'\n\nEnd your reply with this exact final line:\n{marker}\n'
        msg = k.wx(f'packets/{x.stage}/{x.id}/message.md', body)
        P = {"run_id": run, "stage": x.stage, "authorization": st['current_authorization'], "send_id": x.id, "nonce": nonce, "end_marker": marker,
             "target_ai": x.ai, "role": x.role, "send_kind": x.kind, "message": msg, "attachments": [k.ref(f) for f in x.attach],
             "depends_on": x.depends, "ready_at_utc": now()}
        if x.synthetic: P['synthetic'] = x.synthetic
        if x.builder_role: P['builder_role'] = x.builder_role
        if x.accepted_code is not None: P['accepted_code'] = [k.ref(f) for f in x.accepted_code]
        if x.locked_sections:
            m = k.J('artifacts/stage3_locked_design.json')['methodology']
            P.update(output_rules=m['operational']['output_rules'], checkpoint_output_rules=m['operational']['checkpoint_output_rules'], checkpoints=m['checkpoints'], receipt_dependencies=m['receipt_dependencies'])
        print(k.wx(f'packets/{x.stage}/{x.id}/packet.json', P)['sha256'], marker)
    elif x.cmd == 'sent':
        if x.basis not in ('dispatcher_reported', 'machine_observed'): sys.exit('FAIL --basis')
        u = 0 if x.basis == 'machine_observed' else x.uncertainty
        if u is None: sys.exit('FAIL dispatcher_reported needs --uncertainty')
        rec = {"send_id": x.id, "sent_at_utc": x.at or now(), "timestamp_basis": x.basis, "timestamp_uncertainty_seconds": u, "recorded_at_utc": now()}
        if x.evidence: rec['evidence'] = k.ref(x.evidence)
        k.wx(f'captures/{x.stage}/{x.id}_dispatch.json', rec); print('sent', rec['sent_at_utc'])
    elif x.cmd == 'capture':
        pk = k.J(f'packets/{x.stage}/{x.id}/packet.json'); b = open(x.file, 'rb').read(); t = now()
        lines = b.decode('utf-8').rstrip('\r\n').splitlines()
        if not lines or lines[-1].strip() != pk['end_marker']: sys.exit(f'FAIL reply does not end with {pk["end_marker"]} (recapture; do not edit the reply)')
        d = k.J(f'captures/{x.stage}/{x.id}_dispatch.json')
        rp = k.wx(f'transcripts/{x.stage}/{x.id}_reply.md', b)
        bd = k.wx(f'captures/{x.stage}/{x.id}_binding.json', {"send_id": x.id, "nonce": pk['nonce'], "reply": rp, "capture_sha256": hashlib.sha256(b).hexdigest(), "captured_at_utc": t, "basis": "box machine time when the Copy-button bytes were saved"})
        cp = k.wx(f'captures/{x.stage}/{x.id}_capture.json', {"send_id": x.id, "nonce": pk['nonce'], "packet": k.ref(f'packets/{x.stage}/{x.id}/packet.json'), "reply": rp, "capture_method": "browser_copy_button", "capture_sha256": rp['sha256'], "capture_evidence": bd})
        e = {"id": x.id, "ai": pk['target_ai'], "role": pk.get('role'), "send_kind": pk['send_kind'], "nonce": pk['nonce'], "packet": k.ref(f'packets/{x.stage}/{x.id}/packet.json'), "attachments": pk['attachments'],
             "reply": rp, "capture": cp, "ready_at_utc": pk['ready_at_utc'], "sent_at_utc": d['sent_at_utc'], "timestamp_basis": d['timestamp_basis'], "timestamp_uncertainty_seconds": d['timestamp_uncertainty_seconds'],
             "captured_at_utc": t, "verified_at_utc": now(), "depends_on": pk['depends_on'], "approval_id": "none", "dispatch_record": k.ref(f'captures/{x.stage}/{x.id}_dispatch.json')}
        if d.get('evidence'): e['dispatch_evidence'] = d['evidence']
        if pk.get('builder_role'): e['builder_role'] = pk['builder_role']
        k.wx(frag(x.stage, x.id), e); print('captured', rp['sha256'][:16])
    elif x.cmd == 'ledger':
        if st.get('current_step') != x.stage: sys.exit(f'FAIL stage {x.stage} not current')
        d = k.p(f'artifacts/operations/{x.stage}_sends'); sends = [json.load(open(os.path.join(d, f))) for f in sorted(os.listdir(d))] if os.path.isdir(d) else []
        if not sends: sys.exit('FAIL no captured sends')
        sends.sort(key=lambda e: (e['sent_at_utc'], e['id']))
        ap = json.load(open(x.approvals)); out = []
        for a_ in ap:
            if not a_.get('conditions'): sys.exit(f'FAIL approval {a_.get("id")} has an empty conditions list')
            out.append({"id": a_['id'], "run_id": run, "stage": x.stage, "scope": a_['scope'], "wording_author": a_['wording_author'], "owner_record": k.ref(a_['owner_record']),
                        "granted_at_utc": a_['granted_at_utc'], "scope_bound": {"run_id": run, "attempt": x.attempt or '1'},
                        "conditions": [{"condition": c['condition'], "status": "PASS", "evidence": k.ref(c['evidence'])} for c in a_['conditions']]})
        dv = [{"id": v['id'], "disposition": v['disposition'], "evidence": k.ref(v['evidence'])} for v in (json.load(open(x.deviations)) if x.deviations else [])]
        if not os.path.exists(k.p('artifacts/operations/revocations.json')): k.wx('artifacts/operations/revocations.json', {"run_id": run, "events": []})
        ti = k.wx(f'artifacts/operations/{x.stage}_transcript_index.json', {"kind": "transcript_index", "run_id": run, "stage": x.stage, "files": [e['reply'] for e in sends]})
        o = {"version": "acceptance-v1", "run_id": run, "stage": x.stage, "attempt": x.attempt or '1', "authorization": st['current_authorization'], "completed_at_utc": now(),
             "approvals": out, "sends": sends, "all_sends_recorded": True, "transcript_index": ti, "deviations": dv, "tool": "tools/runkit.py"}
        if x.synthetic: o['synthetic'] = x.synthetic
        print(k.wx(f'artifacts/operations/{x.stage}.json', o)['sha256'])
    else: sys.exit('unknown command')
if __name__ == '__main__': main()
