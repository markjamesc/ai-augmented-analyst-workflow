#!/usr/bin/env python3
"""Run tooling (coordinator scripts, not gate code): evidence-scope snapshots and the ref-scope guard.

Problem fixed: historical records (verify_run pass archives, versioned/ sandbox reports, earlier attempts) carry refs
written root-relative or sandbox-relative; later steps overwrite those root paths, so a receipt that cites the historical
record ends up with a stale hash closure.  Fix at the source: receipts cite a write-once *snapshot* of the record.
  snapshot ROOT PATH [--name N]   copy PATH and its whole ref closure into evidence_snapshots/<N>/; every nested ref is
                                  resolved against the root or an ancestor directory of the citing file (sandbox base) and
                                  must match its recorded sha256 NOW (otherwise FAIL: nothing is guessed); refs in the copies
                                  are rewritten to the snapshot copies; manifest.json records every original path+sha.
  guard ROOT FILE...              FAIL if the ref closure of FILE(s) has a missing/stale hash, cites a historical-scope path
                                  outside evidence_snapshots/, or a snapshot file cites outside its own snapshot.
No check is relaxed: a ref that cannot be matched by hash is reported, never rewritten.
"""
import json, hashlib, os, re, sys, shutil, glob
SNAP = 'evidence_snapshots'
HIST = re.compile(r'(^|/)(runs|versioned|sandbox|superseded|failed_attempts)(/|$)|attempt\d|_attempt|pass\d(/|$)', re.I)
def sha(p): return hashlib.sha256(open(p, 'rb').read()).hexdigest()
def norm(p): return p.replace('\\', '/').lstrip('./') if not p.startswith('../') else p.replace('\\', '/')
# Aligned with the gate's m_refs (owner card t1637s6856): any object with both a path and a sha256 field is a reference, whatever the values.
def isref(x): return isinstance(x, dict) and 'path' in x and 'sha256' in x
def goodref(x): return isinstance(x.get('path'), str) and isinstance(x.get('sha256'), str) and re.fullmatch(r'[0-9a-fA-F]{64}', x['sha256']) is not None
def refs(x):
    if isref(x): return [x]
    if isinstance(x, dict): return [r for v in x.values() for r in refs(v)]
    if isinstance(x, list): return [r for v in x for r in refs(v)]
    return []
def load(p):
    try: return json.load(open(p, encoding='utf-8-sig'))
    except Exception: return None
def wx(p, data):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'xb') as f: f.write(data)
def candidates(root, citing_rel, ref_path):
    """root-relative candidates: the root itself, then each ancestor dir of the citing file (sandbox-relative refs)."""
    out = [norm(ref_path)]
    d = os.path.dirname(citing_rel)
    while d:
        out.append(norm(d + '/' + ref_path)); d = os.path.dirname(d)
    return out

def snapshot(root, rel, name=None, keep=()):
    # keep: root paths that are identities locked by the design (validation components, replay outputs). A reference to one of these is
    # hash-checked against the current root file and left pointing at the root path, so every copy names the same locked identity.
    root = os.path.abspath(root); rel = norm(rel); keep = {norm(k) for k in keep}
    name = name or re.sub(r'[^A-Za-z0-9_.-]+', '_', rel)
    base = f'{SNAP}/{name}'
    if os.path.exists(os.path.join(root, base)): raise SystemExit(f'FAIL snapshot exists (write-once): {base}')
    manifest = {"kind": "evidence_snapshot", "tool": "tools/scope_refs.py", "source": {"path": rel, "sha256": sha(os.path.join(root, rel))}, "entries": [], "kept": {}}
    done = {}
    stage = os.path.join(root, SNAP, '.staging_' + name)  # built here, renamed into place only when complete (no partial snapshot on failure)
    if os.path.exists(stage): shutil.rmtree(stage)
    phys = lambda d: os.path.join(stage, d[len(base) + 1:])
    def copy(src_rel, want_sha=None):
        if src_rel in done: return done[src_rel]
        p = os.path.join(root, src_rel); b = open(p, 'rb').read(); s = hashlib.sha256(b).hexdigest()
        if want_sha and s != want_sha: raise SystemExit(f'FAIL hash mismatch {src_rel}')
        dst = f'{base}/{"_cited/" + src_rel if src_rel != rel else os.path.basename(rel)}'
        done[src_rel] = dst
        obj = load(p) if src_rel.endswith('.json') else None
        if obj is not None and refs(obj):
            def rw(x):
                if isref(x):
                    if not goodref(x): raise SystemExit(f'FAIL invalid ref in {src_rel}: {x}')
                    if norm(x['path']) in keep:
                        fp = os.path.join(root, norm(x['path']))
                        if not os.path.isfile(fp) or sha(fp) != x['sha256'].lower(): raise SystemExit(f'FAIL kept identity ref not current at root in {src_rel}: {x["path"]}')
                        manifest['kept'][norm(x['path'])] = x['sha256'].lower(); return x
                    hit = next((c for c in candidates(root, src_rel, x['path']) if os.path.isfile(os.path.join(root, c)) and sha(os.path.join(root, c)) == x['sha256'].lower()), None)
                    if hit is None: raise SystemExit(f'FAIL unresolvable ref in {src_rel}: {x["path"]} {x["sha256"][:12]} (no root/ancestor file with that hash)')
                    nd = copy(hit, x['sha256'].lower()); y = dict(x); y['path'] = nd; y['sha256'] = sha(phys(nd)); y['snapshot_of'] = {"path": x['path'], "sha256": x['sha256'], "resolved": hit}
                    return y
                if isinstance(x, dict): return {k: rw(v) for k, v in x.items()}
                if isinstance(x, list): return [rw(v) for v in x]
                return x
            data = (json.dumps(rw(obj), indent=1, ensure_ascii=False) + '\n').encode()
        else: data = b
        wx(phys(dst), data)
        manifest['entries'].append({"original": {"path": src_rel, "sha256": s}, "copy": {"path": dst, "sha256": hashlib.sha256(data).hexdigest()}, "rewritten": data != b})
        return dst
    try:
        top = copy(rel)
        wx(phys(base + '/manifest.json'), (json.dumps(manifest, indent=1) + '\n').encode())
        for dp, _, fs in os.walk(stage):
            for f in fs: os.chmod(os.path.join(dp, f), 0o444)
        os.rename(stage, os.path.join(root, base))
    except BaseException:
        shutil.rmtree(stage, ignore_errors=True); raise
    return top

# Scoped exception, owner-approved option (a) on card t1637s6850 (2026-10-31 11:55 CT).  The Stage 3 lock requires the methodology
# receipt to depend on the live outputs/verification/replay.json, which validation/check_methodology.R writes with refs into its own
# current output dir outputs/verification/runs/methodology_<ts>/.  Admitted ONLY when all hold:
#   the citing file is exactly the root-scope outputs/verification/replay.json;
#   the cited path is outputs/verification/runs/methodology_<YYYYMMDDTHHMMSSZ>/<file> (one level, no other runs/ dir);
#   that replay.json was written in this execution: recorded_at_utc >= checked_at_utc of the latest PASS execution-begin record
#   in artifacts/procedure/checks, and the <ts> dir is in [execution begin, replay recorded_at] (so a replay from another run or
#   from an earlier execution begin of this run is refused).  Hashes are still checked as for every ref.
METH_RUN = re.compile(r'^outputs/verification/runs/methodology_(\d{8}T\d{6}Z)/[^/]+$')
REPLAY = 'outputs/verification/replay.json'
def _iso(t): return t.replace('-', '').replace(':', '')
def replay_exception(root, rel, p):
    m = METH_RUN.match(p)
    if rel != REPLAY or not m: return False
    begins = [load(f) for f in glob.glob(os.path.join(root, 'artifacts/procedure/checks/execution-begin-*.json'))]
    begins = [b['checked_at_utc'] for b in begins if b and b.get('result') == 'PASS' and b.get('checked_at_utc')]
    rp = load(os.path.join(root, REPLAY))
    if not begins or not rp or not rp.get('recorded_at_utc'): return False
    b0 = _iso(max(begins)); rec = _iso(rp['recorded_at_utc'])
    return b0 <= rec and b0 <= m.group(1) <= rec

def guard(root, files):
    root = os.path.abspath(root); errs = []; seen = set()
    def walk(rel, scope):
        if rel in seen: return
        seen.add(rel); obj = load(os.path.join(root, rel)) if rel.endswith('.json') else None
        for r in refs(obj) if obj is not None else []:
            if not goodref(r): errs.append(f'{rel}: invalid reference (path/sha256 not a path and 64-hex hash): {r}'); continue
            p = norm(r['path']); fp = os.path.join(root, p)
            if not os.path.isfile(fp): errs.append(f'{rel}: missing {p}'); continue
            if sha(fp) != r['sha256'].lower(): errs.append(f'{rel}: stale hash {p}')
            if p.startswith(SNAP + '/'):
                s = '/'.join(p.split('/')[:2])
                if scope and s != scope: errs.append(f'{rel}: snapshot {scope} cites another snapshot {p}')
                walk(p, s)
            else:
                kept = (load(os.path.join(root, scope, 'manifest.json')) or {}).get('kept', {}) if scope else {}
                if scope and not (kept.get(p) == r['sha256'].lower() and not HIST.search(p)): errs.append(f'{rel}: snapshot {scope} cites outside itself: {p}')
                if HIST.search(p) and not (scope is None and replay_exception(root, rel, p)): errs.append(f'{rel}: cites historical-scope record by root path: {p}')
                walk(p, None)
    for f in files:
        f = norm(f); walk(f, '/'.join(f.split('/')[:2]) if f.startswith(SNAP + '/') else None)
    return errs

if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'snapshot':
        name = sys.argv[sys.argv.index('--name') + 1] if '--name' in sys.argv else None
        print(snapshot(sys.argv[2], sys.argv[3], name))
    elif cmd == 'guard':
        e = guard(sys.argv[2], sys.argv[3:])
        print('\n'.join(e) if e else 'PASS ref-scope guard: %d file(s)' % len(sys.argv[3:])); sys.exit(1 if e else 0)
