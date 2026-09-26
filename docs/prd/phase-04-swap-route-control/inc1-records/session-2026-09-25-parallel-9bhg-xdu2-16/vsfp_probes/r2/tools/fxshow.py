#!/usr/bin/env python3
"""fxshow.py BIN FIXTURE_BASENAME... : run BIN on each ir-pass/test fixture with the
drop census lever, print rc, stderr head and @main (minus boilerplate)."""
import os
import re
import subprocess
import sys

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8'
BIN = sys.argv[1]
for n in sys.argv[2:]:
    f = f'{W}/ir-pass/test/{n}.ll'
    r = subprocess.run([BIN, '-passes=cq-lowering', '-S', f, '-o', '-'], capture_output=True,
                       text=True, env=dict(os.environ, CQ_DEADARG_DBG='1', CQ_DEADCONE_DBG='1'))
    print(f'=== {n} rc={r.returncode}')
    for l in r.stderr.splitlines()[:6]:
        print('  ERR', l[:200])
    m = re.search(r'define [^\n]*@(main|example|f|F)\(.*?\n}\n', r.stdout, re.S)
    if m:
        for l in m.group(0).splitlines():
            if 'getelementptr' in l or 'load ptr' in l or '@atoi' in l:
                continue
            print('  ', l[:180])
