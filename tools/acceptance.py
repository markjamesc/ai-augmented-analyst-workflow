#!/usr/bin/env python3
"""Deterministic acceptance helpers. None authorizes browser dispatch or certifies AI identity."""
import argparse, hashlib, json, re, sys
from datetime import datetime, timezone
from pathlib import Path


def utc():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


def time(s):
    if not isinstance(s, str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', s):
        raise ValueError('UTC second-resolution timestamp required')
    return datetime.strptime(s, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def file(root, ref):
    p = ref['path']
    if not isinstance(p, str) or re.match(r'^(/|[A-Za-z]:|\\)', p) or any(x in ('', '.', '..') for x in re.split(r'[/\\]', p)):
        raise ValueError('unsafe path')
    f = (root / p).resolve()
    if not f.is_relative_to(root.resolve()) or not f.is_file():
        raise ValueError('missing or escaped file: ' + p)
    if hashlib.sha256(f.read_bytes()).hexdigest() != ref['sha256']:
        raise ValueError('hash mismatch: ' + p)
    return f


def refs(obj):
    if isinstance(obj, dict):
        if 'path' in obj and 'sha256' in obj:
            yield obj
        else:
            for v in obj.values():
                yield from refs(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from refs(v)


def check(command, root, x):
    result = {'status': 'PASS', 'recorded_at_utc': utc()}
    if command == 'stamp':
        return result
    if command == 'watchdog':
        now = time(x.get('now_utc', utc()))
        tasks = x['tasks']
        if len({t['id'] for t in tasks}) != len(tasks):
            raise ValueError('duplicate task')
        overdue = []
        for t in tasks:
            ready = time(t['ready_at_utc'])
            if ready > now:
                raise ValueError('future readiness')
            uncertainty = t.get('timestamp_uncertainty_seconds', 0)
            if not isinstance(uncertainty, (int, float)) or isinstance(uncertainty, bool) or not 0 <= uncertainty < float('inf'):
                raise ValueError('invalid timing uncertainty')
            if t['status'] == 'ready' and (now-ready).total_seconds() + uncertainty > 900:
                overdue.append(t['id'])
        result.update(status='FLAG' if overdue else 'PASS', overdue=overdue)
    elif command == 'capture':
        packet = read(file(root, x['packet']))
        reply = file(root, x['reply']).read_text(encoding='utf-8')
        if not x.get('screen_verified') or not x.get('nonce') or packet['nonce'] != x['nonce'] or packet['send_id'] != x['send_id'] or not reply.rstrip().endswith('END_REPLY '+x['send_id']+' '+x['nonce']):
            raise ValueError('stale/incomplete capture or missing visual verification')
        if x.get('capture_method') not in ('screenshot', 'screen_recording', 'browser_export'):
            raise ValueError('retained capture evidence required; bare attestation is insufficient')
        file(root, x['capture_evidence'])
        result.update(x)
        result['recorded_at_utc'] = utc()
    elif command == 'packet':
        state = read(root/'artifacts/procedure/run_state.json')
        if x['run_id'] != state['run_id'] or x['stage'] != state['current_step'] or x['authorization'] != state['current_authorization']:
            raise ValueError('packet authorization mismatch')
        begin = read(file(root, x['authorization']))
        if begin['phase'] != 'begin' or begin['result'] != 'PASS' or begin['step'] != x['stage']:
            raise ValueError('begin not passed')
        # D-20: preflight checks the full declared JSON reference closure.
        check('file-inventory', root, {'seeds': list(refs(x))})
        if x['stage'] == 'execution':
            m = read(root/'artifacts/stage3_locked_design.json')['methodology']
            if x['output_rules'] != m['operational']['output_rules'] or x['checkpoint_output_rules'] != m['operational']['checkpoint_output_rules'] or x['checkpoints'] != m['checkpoints'] or x['receipt_dependencies'] != m['receipt_dependencies'] or not isinstance(x['accepted_code'], list):
                raise ValueError('incomplete locked packet sections')
        result['non_authorizing'] = True
    elif command == 'inventory':
        rows = x['files']
        if len({r['path'] for r in rows}) != len(rows):
            raise ValueError('duplicate inventory entry')
        for row in rows:
            lines = file(root, row).read_text(encoding='utf-8').splitlines()
            if row['line_count'] != len(lines) or row['first_line'] != (lines[0] if lines else '') or row['last_line'] != (lines[-1] if lines else ''):
                raise ValueError('file-access inventory mismatch: '+row['path'])
    elif command == 'revision':
        old = file(root, x['original']).read_text(encoding='utf-8')
        for edit in x['replacements']:
            if not edit['old'] or old.count(edit['old']) != 1:
                raise ValueError('replacement must match exactly once')
            old = old.replace(edit['old'], edit['new'], 1)
        if old != file(root, x['revised']).read_text(encoding='utf-8'):
            raise ValueError('unapproved change or unresolved replacement')
    elif command == 'claims':
        flags = []
        for c in x['claims']:
            words = set(re.findall(r'[a-z0-9]+', c['wording'].lower()))
            if c['type'] == 'recommendation' or words.intersection(x['action_lexicon']):
                if not all(c.get(k) for k in ('owner_tradeoff', 'action', 'evidence_tag', 'tag_assigned_by')):
                    flags.append(c['id'])
            if words.intersection(x['finality_lexicon']):
                file(root, c['monitoring_next_question_review'])
        result.update(status='FLAG' if flags else 'PASS', flagged_claims=flags)
    elif command == 'file-inventory':
        seen = {}
        def visit(ref):
            f = file(root, ref)
            if ref['path'] in seen:
                if seen[ref['path']]['sha256'] != ref['sha256']:
                    raise ValueError('conflicting identity')
                return
            seen[ref['path']] = dict(path=ref['path'], sha256=ref['sha256'], bytes=f.stat().st_size)
            if f.suffix.lower() == '.json':
                for r in refs(read(f)):
                    visit(r)
        for r in x['seeds']:
            visit(r)
        result['files'] = [seen[k] for k in sorted(seen)]
    else:
        raise ValueError('unknown command')
    return result


def main():
    p = argparse.ArgumentParser()
    p.add_argument('command', choices=['stamp', 'capture', 'packet', 'watchdog', 'inventory', 'revision', 'claims', 'file-inventory'])
    p.add_argument('root', type=Path)
    p.add_argument('input', type=Path)
    p.add_argument('--out', required=True, type=Path)
    a = p.parse_args()
    try:
        result = check(a.command, a.root.resolve(), read(a.input))
        code = 1 if result['status'] == 'FLAG' else 0
    except (KeyError, ValueError, TypeError, OSError) as e:
        result, code = {'status': 'FAIL', 'error': str(e), 'recorded_at_utc': utc()}, 2
    with a.out.open('x', encoding='utf-8') as f:
        json.dump(result, f, indent=2)
        f.write('\n')
    print(json.dumps(result))
    return code


if __name__ == '__main__':
    sys.exit(main())
