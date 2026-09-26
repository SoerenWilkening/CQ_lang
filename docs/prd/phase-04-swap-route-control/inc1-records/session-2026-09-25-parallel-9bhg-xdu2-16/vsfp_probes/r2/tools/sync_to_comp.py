#!/usr/bin/env python3
"""Mirror the round-2 working-tree state of the vsfp worktree (tracked changes, renames,
deletions and new files under ir-pass/, tests/, CODE_MAP.md) into compwt2."""
import pathlib
import shutil
import subprocess

W = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8')
C = pathlib.Path(__file__).parent / 'compwt2'
r = subprocess.run(['git', 'status', '--porcelain'], cwd=W, capture_output=True, text=True).stdout
n = 0
for line in r.splitlines():
    st, path = line[:2], line[3:]
    if ' -> ' in path:
        old, path = path.split(' -> ')
        (C / old).unlink(missing_ok=True)
    if not (path.startswith('ir-pass/') or path.startswith('tests/') or path == 'CODE_MAP.md'):
        continue
    src, dst = W / path, C / path
    if src.is_dir():
        continue
    if not src.exists():
        dst.unlink(missing_ok=True)
        continue
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    n += 1
print('copied', n)
