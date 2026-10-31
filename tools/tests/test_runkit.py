# Tests for tools/runkit.py (positive and negative; gate acceptance is exercised by the rehearsal). Run: python3 tools/tests/test_runkit.py
import json, os, sys, tempfile, subprocess, hashlib, time
T = os.path.dirname(__file__); RK = os.path.join(T, '..', 'runkit.py'); sys.path.insert(0, os.path.join(T, '..')); import scope_refs as S
n = 0; bad = 0
def ok(name, cond):
    global n, bad; n += 1; bad += (not cond); print(('PASS ' if cond else 'FAIL ') + name)
def rk(*a): return subprocess.run([sys.executable, RK, *a], capture_output=True, text=True)
r = tempfile.mkdtemp(); os.makedirs(f'{r}/artifacts/procedure/checks'); open(f'{r}/artifacts/procedure/checks/b.json', 'w').write('{}'); AU = hashlib.sha256(b'{}').hexdigest(); open(f'{r}/in.txt', 'w').write('input\n')
json.dump({"run_id": "RUNX", "current_step": "start", "started_at_utc": "2026-10-31T00:00:00Z", "current_authorization": {"path": "artifacts/procedure/checks/b.json", "sha256": AU}}, open(f'{r}/artifacts/procedure/run_state.json', 'w'))
open(f'{r}/m.md', 'w').write('hello')
ok('packet refused when stage is not current', rk('packet', r, 'framing', 'S2-01', '--ai', 'A', '--role', 'x', '--kind', 'review', '--message', f'{r}/m.md').returncode != 0)
for bad_id in ['S1-attempt2', 'attempt-1', 'S1/../x', 'pass2', 'S1 01']:
    ok(f'packet refuses unsafe send id {bad_id!r}', rk('packet', r, 'start', bad_id, '--ai', 'A', '--role', 'x', '--kind', 'review', '--message', f'{r}/m.md').returncode != 0)
x = rk('packet', r, 'start', 'S1-01', '--ai', 'A', '--role', 'x', '--kind', 'review', '--message', f'{r}/m.md', '--attach', 'in.txt'); ok('packet written', x.returncode == 0)
P = json.load(open(f'{r}/packets/start/S1-01/packet.json'))
ok('packet binds run, nonce, marker, attachment hash', P['run_id'] == 'RUNX' and len(P['nonce']) == 16 and P['end_marker'] == f'END_REPLY S1-01 {P["nonce"]}' and P['attachments'][0]['sha256'] == hashlib.sha256(b'input\n').hexdigest())
ok('message ends with the marker instruction', open(f'{r}/packets/start/S1-01/message.md').read().rstrip().endswith(P['end_marker']))
ok('packet is write-once', rk('packet', r, 'start', 'S1-01', '--ai', 'A', '--role', 'x', '--kind', 'review', '--message', f'{r}/m.md').returncode != 0)
ok('packet files are read-only', not os.access(f'{r}/packets/start/S1-01/packet.json', os.W_OK) or os.geteuid() == 0)
ok('sent command removed (audit-only, t1660u)', rk('sent', r, 'start', 'S1-01').returncode != 0)
ok('packet has no audit-only fields', not ({'authorization', 'ready_at_utc'} & set(P)))
open(f'{r}/bad.md', 'w').write('reply without marker\n'); open(f'{r}/wrong.md', 'w').write('reply\nEND_REPLY S1-01 deadbeefdeadbeef\n')
ok('capture refuses reply with no marker', rk('capture', r, 'start', 'S1-01', f'{r}/bad.md').returncode != 0)
ok('capture refuses reply with wrong nonce', rk('capture', r, 'start', 'S1-01', f'{r}/wrong.md').returncode != 0)
ok('refused capture wrote nothing', not os.path.exists(f'{r}/transcripts/start/S1-01_reply.md'))
reply = f'answer\n{P["end_marker"]}\n'.encode(); open(f'{r}/good.md', 'wb').write(reply)
ok('capture accepted', rk('capture', r, 'start', 'S1-01', f'{r}/good.md').returncode == 0)
F = json.load(open(f'{r}/artifacts/operations/start_sends/S1-01.json'))
ok('capture stores exact bytes and binds them', open(f'{r}/transcripts/start/S1-01_reply.md', 'rb').read() == reply and F['reply']['sha256'] == hashlib.sha256(reply).hexdigest() and json.load(open(f'{r}/captures/start/S1-01_capture.json'))['capture_sha256'] == F['reply']['sha256'])
ok('capture fragment keeps role, nonce, packet, attachments; no chronology/dispatch fields', F['nonce'] == P['nonce'] and F['role'] == 'x' and F['packet']['path'].endswith('packet.json') and F['attachments'] == P['attachments'] and not ({'sent_at_utc', 'ready_at_utc', 'verified_at_utc', 'dispatch_record', 'approval_id'} & set(F)))
ok('capture is write-once', rk('capture', r, 'start', 'S1-01', f'{r}/good.md').returncode != 0)
ok('ledger refused for a stage that is not current', rk('ledger', r, 'framing').returncode != 0)
ok('ledger written', rk('ledger', r, 'start').returncode == 0)
L = json.load(open(f'{r}/artifacts/operations/start.json'))
ok('ledger: run, sends only; no audit-only fields', L['run_id'] == 'RUNX' and L['version'] == 'acceptance-v2' and [e['id'] for e in L['sends']] == ['S1-01'] and not ({'approvals', 'deviations', 'transcript_index', 'all_sends_recorded', 'authorization', 'completed_at_utc'} & set(L)) and not os.path.exists(f'{r}/artifacts/operations/revocations.json'))
ok('no binding or dispatch files written', not [f for f in os.listdir(f'{r}/captures/start') if f.endswith(('_binding.json', '_dispatch.json'))])
paths = []
for dp, _, fs in os.walk(r): paths += [os.path.relpath(os.path.join(dp, f), r) for f in fs]
ok('no runkit-written path matches the guard historical pattern', not [p for p in paths if S.HIST.search(p.replace(os.sep, '/'))])
ok('ref-scope guard passes on the ledger', S.guard(r, ['artifacts/operations/start.json']) == [])
print(f'{n - bad}/{n} passed'); sys.exit(1 if bad else 0)
