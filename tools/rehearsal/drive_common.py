# SYNTHETIC rehearsal driver helpers (owner card t1636s6840). Box only. Uses the run tools the live run will use.
import json, os, subprocess, sys, time, hashlib, re, shutil, datetime
RS = '/opt/mamba/envs/r/bin/Rscript'; PY = sys.executable
LAB = 'SYNTHETIC REHEARSAL (owner card t1636s6840): stand-in reply written by the coordinator, NOT a real AI reply'
class D:
    def __init__(s, root, gate):
        s.root, s.G = os.path.abspath(root), os.path.abspath(gate); s.log = open(os.path.join(os.path.dirname(s.root), os.path.basename(s.root) + '_drive.log'), 'a')
    def p(s, r): return os.path.join(s.root, r)
    def sha(s, r): return hashlib.sha256(open(s.p(r), 'rb').read()).hexdigest()
    def ref(s, r): return {"path": r, "sha256": s.sha(r)}
    def J(s, r): return json.load(open(s.p(r), encoding='utf-8-sig'))
    def wx(s, r, o):
        os.makedirs(os.path.dirname(s.p(r)), exist_ok=True)
        with open(s.p(r), 'x', encoding='utf-8', newline='\n') as f: f.write(o if isinstance(o, str) else json.dumps(o, indent=1, ensure_ascii=False) + '\n')
        return s.ref(r)
    def run(s, cmd, ok=(0,), cwd=None):
        r = subprocess.run(cmd, cwd=cwd or s.root, capture_output=True, text=True)
        s.log.write(f'$ {" ".join(cmd)}\nexit={r.returncode}\n{r.stdout[-4000:]}\n{r.stderr[-4000:]}\n'); s.log.flush()
        if r.returncode not in ok: print(r.stdout[-3000:], r.stderr[-3000:]); raise SystemExit(f'command failed ({r.returncode}): {" ".join(cmd)}')
        return r
    def gate(s, *a, ok=(0,)): return s.run([RS, '--vanilla', f'{s.G}/procedure-gate/procedure_gate.R', a[0], s.root, *a[1:]], ok=ok)
    def kit(s, *a): return s.run([PY, f'{s.G}/tools/runkit.py', a[0], s.root, *a[1:]])
    def send(s, stage, sid, ai, role, kind, body, attach=(), depends=(), reply_body=None, extra=()):
        """packet -> (owner/parent dispatches) -> sent record -> Copy-button bytes -> capture.  Here the reply is SYNTHETIC."""
        msg = f'/tmp/reh_msg_{sid}.md'; open(msg, 'w').write(body)
        out = s.kit('packet', stage, sid, '--ai', ai, '--role', role, '--kind', kind, '--message', msg, '--synthetic', LAB, '--attach', *attach, '--depends', *depends, *extra).stdout.split()
        marker = ' '.join(out[1:4]); time.sleep(1)
        s.kit('sent', stage, sid, '--basis', 'dispatcher_reported', '--uncertainty', '2'); time.sleep(3)
        rep = f'/tmp/reh_reply_{sid}.md'; open(rep, 'w', newline='\n').write(f'{LAB}\n\n{reply_body or "VERDICT: PASS"}\n\n{marker}\n')
        s.kit('capture', stage, sid, rep); time.sleep(3)
        return f'transcripts/{stage}/{sid}_reply.md'
    def owner(s, stage, text):
        return s.wx(f'approvals/SYNTHETIC_owner_{stage}.md', f'# {LAB}\nSYNTHETIC stand-in for the owner record of stage {stage}: {text}\nRecorded {datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}\n')
    def ledger(s, stage, conds, extra_scopes=()):
        own = f'approvals/SYNTHETIC_owner_{stage}.md'; t = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        ap = [{"id": f"SYN-{stage}-{sc}", "scope": sc, "wording_author": "SYNTHETIC owner stand-in", "owner_record": own, "granted_at_utc": t, "conditions": [{"condition": c, "evidence": e} for c, e in conds]} for sc in ('stage_signoff',) + tuple(extra_scopes)]
        dv = self_dev = s.wx(f'deviations/SYNTHETIC_{stage}.json', {"id": f"DEV-{stage}-SYNTHETIC", "disposition": "All replies and owner records in this stage are SYNTHETIC stand-ins (rehearsal)", "synthetic": LAB})
        af = f'/tmp/reh_ap_{stage}.json'; json.dump(ap, open(af, 'w')); df = f'/tmp/reh_dv_{stage}.json'
        json.dump([{"id": f"DEV-{stage}-SYNTHETIC", "disposition": "rehearsal: synthetic replies and owner records, disclosed", "evidence": f'deviations/SYNTHETIC_{stage}.json'}], open(df, 'w'))
        time.sleep(1); s.kit('ledger', stage, '--approvals', af, '--deviations', df, '--synthetic', LAB)
    def complete(s, stage, ok=(0,)):
        r = s.gate('complete', stage, ok=(0, 1)); res = json.loads(r.stdout[r.stdout.index('{'):]) if '{' in r.stdout else {}
        ch = res.get('checks', [])
        if not ch and isinstance(res.get('check_report'), dict):
            cp = res['check_report'].get('path'); cp = cp if os.path.isabs(cp) else s.p(cp); ch = json.load(open(cp)).get('checks', [])
        fails = [c for c in ch if c.get('result') != 'PASS']
        print(f'complete {stage}: {res.get("status")}  {len(ch)-len(fails)}/{len(ch)} PASS'); [print('   FAIL', c.get('check'), '|', str(c.get('detail'))[:200]) for c in fails]
        return res, len(ch) - len(fails), len(ch)
