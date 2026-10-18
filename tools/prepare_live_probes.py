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
for name in ['early','changed-rb','condition','revocation','stale-capture']:
    root=dest/name
    shutil.copytree(source,root)
    (root/'SYNTHETIC_NEGATIVE_PROBE.txt').write_text('Deliberately altered COPY of clean fixture; never certification evidence.\n')
    state=load(root/'artifacts/procedure/run_state.json')
    op=root/'artifacts/operations/finish.json'
    if name=='early':
        x=load(op);x['sends'][0]['ready_at_utc']='2000-01-01T00:00:00Z';x['sends'][0]['sent_at_utc']='2000-01-01T00:00:01Z';save(op,x)
    elif name=='changed-rb':
        s3=load(root/'artifacts/stage3_locked_design.json')
        paths=s3['methodology']['operational']['validation_components']['R-B']
        rb=next((f for f in paths if f.lower().endswith('.r')),None)
        if not rb:raise ValueError('R-B must identify its actual R script for this test')
        with (root/rb).open('a',encoding='utf-8') as f:f.write('\n# synthetic acceptance probe: harmless byte change\n')
    elif name=='condition':
        x=load(op)
        for app in x['approvals']:
            if app['scope']=='stage_signoff':app['conditions']=[dict(condition='Deliberately false synthetic condition',status='FAIL',evidence=x['transcript_index'])]
        save(op,x)
    elif name=='revocation':
        x=load(op);rev=root/'artifacts/operations/revocations.json';v=load(rev)
        for app in x['approvals']:
            if app['scope']=='stage_signoff':v['events'].append(dict(approval_id=app['id'],recorded_at_utc=x['completed_at_utc'],owner_record=app['owner_record']))
        save(rev,v)
    else:
        s=load(op)['sends'][0];packet=load(root/s['packet']['path']);packet['nonce']='FRESH_NEGATIVE_TEST_NONCE'
        save(root/'probe-packet.json',packet)
        save(root/'probe-capture.json',dict(send_id=s['id'],nonce=packet['nonce'],packet=ref(root,'probe-packet.json'),reply=s['reply'],screen_verified=True,capture_method=load(root/s['capture']['path'])['capture_method'],capture_evidence=load(root/s['capture']['path'])['capture_evidence']))
save(dest/'watchdog.json',dict(now_utc='2026-01-01T00:15:01Z',tasks=[dict(id='SYNTHETIC-overdue',status='ready',ready_at_utc='2026-01-01T00:00:00Z')]))
print('Prepared five labeled copies and synthetic overdue queue at',dest)
