import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from acceptance import check


class Acceptance(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def put(self, p, text):
        (self.root/p).write_text(text)
        return dict(path=p, sha256=hashlib.sha256(text.encode()).hexdigest())

    def test_capture(self):
        p = self.put('p.json', json.dumps(dict(send_id='s', nonce='n')))
        r = self.put('r.txt', 'actual reply\nEND_REPLY s n')
        x = dict(send_id='s', nonce='n', packet=p, reply=r, screen_verified=True, capture_method='browser_export', capture_evidence=self.put('capture.txt','SYNTHETIC browser export'))
        self.assertEqual(check('capture', self.root, x)['status'], 'PASS')
        for key, value in [('nonce', 'old'), ('screen_verified', False), ('send_id', 'old')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                check('capture', self.root, dict(x, **{key:value}))

    def test_capture_requires_retained_evidence(self):
        p=self.put('p.json',json.dumps(dict(send_id='s',nonce='n')))
        r=self.put('r.txt','END_REPLY s n')
        with self.assertRaises(ValueError):
            check('capture',self.root,dict(send_id='s',nonce='n',packet=p,reply=r,screen_verified=True))

    def test_uncertain_timing_cannot_be_claimed_timely(self):
        x=dict(now_utc='2026-01-01T00:14:59Z',tasks=[dict(id='s',status='ready',ready_at_utc='2026-01-01T00:00:00Z',timestamp_uncertainty_seconds=5)])
        self.assertEqual(check('watchdog',self.root,x)['status'],'FLAG')

    def test_changed_reply(self):
        p = self.put('p.json', json.dumps(dict(send_id='s', nonce='n')))
        r = self.put('r.txt', 'END_REPLY s n')
        self.put('r.txt', 'old')
        with self.assertRaises(ValueError):
            check('capture',self.root,dict(send_id='s',nonce='n',packet=p,reply=r,screen_verified=True))

    def test_inventory_lines(self):
        r = self.put('f.txt', 'first\nlast\n')
        row = dict(r,line_count=2,first_line='first',last_line='last')
        self.assertEqual(check('inventory',self.root,{'files':[row]})['status'],'PASS')
        for key,value in [('line_count',3),('first_line','fir'),('last_line','las')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                check('inventory',self.root,{'files':[dict(row,**{key:value})]})

    def test_watchdog_boundary(self):
        x=dict(tasks=[dict(id='s',status='ready',ready_at_utc='2026-01-01T00:00:00Z')])
        self.assertEqual(check('watchdog',self.root,dict(x,now_utc='2026-01-01T00:15:00Z'))['status'],'PASS')
        self.assertEqual(check('watchdog',self.root,dict(x,now_utc='2026-01-01T00:15:01Z'))['status'],'FLAG')

    def test_revision(self):
        x=dict(original=self.put('a.txt','A B'),revised=self.put('b.txt','A C'),replacements=[dict(old='B',new='C')])
        self.assertEqual(check('revision',self.root,x)['status'],'PASS')
        x['revised']=self.put('b.txt','D C')
        with self.assertRaises(ValueError):check('revision',self.root,x)

    def test_transitive_inventory(self):
        ref=self.put('c.txt','child')
        parent=self.put('p.json',json.dumps({'child':ref}))
        self.assertEqual(len(check('file-inventory',self.root,{'seeds':[parent]})['files']),2)
        self.put('c.txt','changed')
        with self.assertRaises(ValueError):check('file-inventory',self.root,{'seeds':[parent]})

    def test_unsafe_path(self):
        with self.assertRaises(ValueError):check('file-inventory',self.root,{'seeds':[dict(path='../outside',sha256='0'*64)]})

    def test_claim_action(self):
        x=dict(action_lexicon=['increase'],finality_lexicon=['conclusive'],claims=[dict(id='c',type='descriptive',wording='increase prices')])
        self.assertEqual(check('claims',self.root,x)['status'],'FLAG')

    def test_missing_dependency(self):
        p=self.put('p.json',json.dumps(dict(child=dict(path='absent.txt',sha256='0'*64))))
        with self.assertRaises(ValueError):check('file-inventory',self.root,{'seeds':[p]})


if __name__=='__main__':unittest.main()
