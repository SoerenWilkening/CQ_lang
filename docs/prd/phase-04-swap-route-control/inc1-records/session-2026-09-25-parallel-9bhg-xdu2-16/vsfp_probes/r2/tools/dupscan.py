#!/usr/bin/env python3
"""dupscan.py : CLAUDE.md L8's duplicate-body scan — sha-256 over each ir-pass/test fixture's
non-comment, non-blank lines (ModuleID/source_filename dropped); print every group of >1 files
that includes a file this branch added or changed."""
import collections
import hashlib
import pathlib

T = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test')
V = pathlib.Path(__file__).parent
own = set()
for l in (V / 'st_now.txt').read_text().splitlines():
    own.add(l[3:].split(' -> ')[-1].replace('ir-pass/test/', ''))
for l in (V / 'st_r1.txt').read_text().splitlines():
    own.add(l.replace('ir-pass/test/', ''))
groups = collections.defaultdict(list)
for f in sorted(T.glob('*.ll')):
    body = [l for l in f.read_text().splitlines()
            if l.strip() and not l.lstrip().startswith(';')
            and not l.startswith('source_filename') and not l.startswith('; ModuleID')]
    h = hashlib.sha256('\n'.join(body).encode()).hexdigest()[:16]
    groups[h].append(f.name)
n = 0
for h, fs in groups.items():
    if len(fs) > 1 and any(x in own for x in fs):
        n += 1
        print(h, fs)
print('groups with an own file:', n, 'of', sum(1 for fs in groups.values() if len(fs) > 1), 'duplicate groups;',
      len(list(T.glob('*.ll'))), 'fixtures')
