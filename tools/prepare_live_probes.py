#!/usr/bin/env python3
"""Create labeled synthetic negative copies AFTER the clean live fixture.
Never modify source evidence. Not actual AI response generation.
"""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('source',type=Path)
p.add_argument('destination',type=Path)
a=p.parse_args()
source=a.source.resolve();dest=a.destination.resolve()
if dest.exists() or dest.is_relative_to(source):
    raise SystemExit('Destination must be new and outside the source run')
dest.mkdir(parents=True)

def load(path):return json.loads(path.read_text(encoding='utf-8'))
def save(path,value):path.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def ref(root,p):return dict(path=p,sha256=hashlib.sha256((root/p).read_bytes()).hexdigest())
# 2026-10-31 (option B): probes 'early', 'condition', 'revocation' retired with the cut chronology/approval/revocation rules;
# 'control' (unaltered), 'dropped-review' and 'stale-reply' added for review coverage.
for name in ['control','changed-rb','dropped-review','stale-reply','stale-capture']:
    root=dest/name
    shutil.copytree(source,root)
    (root/'SYNTHETIC_NEGATIVE_PROBE.txt').write_text('Deliberately altered COPY of clean fixture; never certification evidence.\n')
    state=load(root/'artifacts/procedure/run_state.json')
    op=root/'artifacts/operations/finish.json'
    if name=='control':
        pass
    elif name=='changed-rb':
        s3=load(root/'artifacts/stage3_locked_design.json')
        paths=s3['methodology']['operational']['validation_components']['R-B']
        rb=next((f for f in paths if f.lower().endswith('.r')),None)
        if not rb:raise ValueError('R-B must identify its actual R script for this test')
        with (root/rb).open('a',encoding='utf-8') as f:f.write('\n# synthetic acceptance probe: harmless byte change\n')
    elif name=='dropped-review':
        x=load(op);n=len(x['sends']);x['sends']=[q for q in x['sends'] if q.get('role')!='numerical_auditor']
        if len(x['sends'])!=n-1:raise ValueError('expected exactly one numerical_auditor send')
        save(op,x)
    elif name=='stale-reply':
        # Consistently re-hashed stale reply: inference_reviewer's reply file replaced by interpreter's bytes, every hash ref updated.
        x=load(op);by={q.get('role'):q for q in x['sends']};i,r=by['interpreter'],by['inference_reviewer']
        (root/r['reply']['path']).write_bytes((root/i['reply']['path']).read_bytes())
        r['reply']=ref(root,r['reply']['path']);c=load(root/r['capture']['path']);c['reply']=r['reply']
        if 'capture_sha256' in c:c['capture_sha256']=r['reply']['sha256']
        save(root/r['capture']['path'],c);r['capture']=ref(root,r['capture']['path']);save(op,x)
    else:
        s=load(op)['sends'][0];packet=load(root/s['packet']['path']);packet['nonce']='FRESH_NEGATIVE_TEST_NONCE'
        save(root/'probe-packet.json',packet)
        save(root/'probe-capture.json',dict(send_id=s['id'],nonce=packet['nonce'],packet=ref(root,'probe-packet.json'),reply=s['reply'],capture_sha256=s['reply']['sha256']))  # acceptance-v2 capture record shape
save(dest/'watchdog.json',dict(now_utc='2026-01-01T00:15:01Z',tasks=[dict(id='SYNTHETIC-overdue',status='ready',ready_at_utc='2026-01-01T00:00:00Z')]))
print('Prepared five labeled copies (control, changed-rb, dropped-review, stale-reply, stale-capture) and synthetic overdue queue at',dest)
