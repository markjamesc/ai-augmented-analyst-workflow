# Tests for the versioned_reports.R console-header overlay (owner card t1638s6865). Needs a Stage-4 rehearsal root as fixture.
# Run: python3 tools/tests/test_versioned_console.py FIXTURE_ROOT
import sys, os, shutil, subprocess, tempfile, glob, hashlib, json
G = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))); RS = '/opt/mamba/envs/r/bin/Rscript'
src = sys.argv[1]; n = bad = 0
def ok(name, c):
    global n, bad; n += 1; bad += (not c); print(('PASS ' if c else 'FAIL ') + name)
t = tempfile.mkdtemp(); r = os.path.join(t, 'root'); shutil.copytree(src, r, symlinks=True)
for d in glob.glob(f'{r}/outputs/verification/versioned/*'): shutil.move(d, d.replace('/versioned/', '/versioned_old_'))
dst = f'{r}/validation/versioned_reports.R'; os.chmod(dst, 0o644); shutil.copy(f'{G}/tools/rehearsal/harness/versioned_reports.R', dst)
p = subprocess.run([RS, '--vanilla', 'validation/versioned_reports.R', r], cwd=r, capture_output=True, text=True)
ok('versioned_reports.R (overlay) exits 0', p.returncode == 0)
cons = sorted(glob.glob(f'{r}/outputs/verification/versioned/*/console/*.txt'))
ok('console captures produced', len(cons) >= 5)
ok('no console capture is empty', all(os.path.getsize(c) > 0 for c in cons))
first = {os.path.basename(c): open(c, 'rb').read().split(b'\n', 1) for c in cons}
ok('every capture starts with a one-line exit-status header', all(v[0].startswith(b'# exit status ') for v in first.values()))
ok('quiet builders are labelled "no output" with nothing after the header', all(first[k][0].endswith(b'no output') and first[k][1] == b'' for k in ('builder_r_a.txt', 'builder_r_b.txt')))
def _strip(b): return b.split(b'\n', 1)[1] if b.startswith(b'# exit status ') else b  # fixture may already carry the overlay header
old = {os.path.basename(c): _strip(open(c, 'rb').read()) for c in glob.glob(f'{r}/outputs/verification/versioned_old_*/console/*.txt')}
ok('non-empty child output follows the header byte for byte (count stated)', all(first[k][1] == old[k] and first[k][0].endswith(f'{len(old[k])} bytes of output follow'.encode()) for k in old if old[k] and k in first))
# references in the report bind the header-bearing bytes
sm = json.load(open(glob.glob(f'{r}/outputs/verification/versioned/*/summary.json')[0]))
def refs(x): return [x] if isinstance(x, dict) and 'path' in x and 'sha256' in x else [y for v in (x.values() if isinstance(x, dict) else x if isinstance(x, list) else []) for y in refs(v)]
con_refs = [x for x in refs(sm) if 'console/' in str(x['path'])]; base = os.path.dirname(glob.glob(f'{r}/outputs/verification/versioned/*/summary.json')[0])
def res(pth): return next((q for q in [os.path.join(base, pth), os.path.join(r, pth)] if os.path.isfile(q)), None)
ok('summary console references match the header-bearing files', con_refs and all(res(x['path']) and hashlib.sha256(open(res(x['path']), 'rb').read()).hexdigest() == x['sha256'] for x in con_refs))
shutil.rmtree(t); print(f'{n - bad}/{n} passed'); sys.exit(1 if bad else 0)
