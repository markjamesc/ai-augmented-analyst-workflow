#!/usr/bin/env python3
"""Run tooling: build outputs/verification/structural_dispositions.json from the structural reviewers' captured replies.
  structural_dispositions.py ROOT STRUCTURAL_SNAPSHOT REVIEW_SEND_ID ...
STRUCTURAL_SNAPSHOT is a scope_refs snapshot of the NEEDS_REVIEW structural.json that was attached to the review packets.
Each reply must classify EVERY flag key on its own line:  FLAG <sha256-key> <FLAG_ONLY|CONFIRMED_SHARING|CORRECTNESS_DEFECT>: <rationale>
A key with a missing or non-unanimous class is a FAIL (nothing is guessed); the file is write-once and hash-binds every reply."""
import json, os, re, sys, hashlib
CL = ('FLAG_ONLY', 'CONFIRMED_SHARING', 'CORRECTNESS_DEFECT')
def sha(p): return hashlib.sha256(open(p, 'rb').read()).hexdigest()
def main(root, snap, sids):
    P = lambda r: os.path.join(root, r); s = json.load(open(P(snap), encoding='utf-8-sig')); f = s['similarity_flags']
    keys = list(f['keys']);
    if len(keys) != f['n']: sys.exit(f'FAIL flag key list ({len(keys)}) != n ({f["n"]})')
    st = json.load(open(P('artifacts/procedure/run_state.json'))); per = {k: {} for k in keys}; why = {k: [] for k in keys}; ev = []
    for sid in sids:
        rp = f'transcripts/execution/{sid}_reply.md'; ev.append({"path": rp, "sha256": sha(P(rp))})
        for m in re.finditer(r'^FLAG ([0-9a-f]{64}) (\w+):\s*(.+)$', open(P(rp), encoding='utf-8').read(), re.M):
            if m.group(1) in per:
                if m.group(2) not in CL: sys.exit(f'FAIL {sid}: unknown class {m.group(2)}')
                per[m.group(1)][sid] = m.group(2); why[m.group(1)].append(f'{sid}: {m.group(3).strip()}')
    flags = []
    for k in keys:
        miss = [x for x in sids if x not in per[k]]
        if miss: sys.exit(f'FAIL flag {k[:12]} not classified by {miss}')
        if len(set(per[k].values())) != 1: sys.exit(f'FAIL flag {k[:12]} classes differ: {per[k]} (owner disposition needed)')
        flags.append({"flag_key": k, "class": next(iter(per[k].values())), "reviewer": ', '.join(sids), "per_reviewer": per[k], "rationale": ' | '.join(why[k]), "evidence": ev})
    o = {"run_id": st['run_id'], "status": "FINAL", "r_a_sha256": sha(P('analysis/r_a/main.R')), "r_b_sha256": sha(P('analysis/r_b/main.R')),
         "structural_snapshot": {"path": snap, "sha256": sha(P(snap))}, "flags": flags, "findings": [], "tool": "tools/structural_dispositions.py"}
    out = P('outputs/verification/structural_dispositions.json')
    with open(out, 'x', newline='\n') as fh: fh.write(json.dumps(o, indent=1) + '\n')
    os.chmod(out, 0o444); print(sha(out), len(flags), 'flags')
if __name__ == '__main__': main(os.path.abspath(sys.argv[1]), sys.argv[2], sys.argv[3:])
