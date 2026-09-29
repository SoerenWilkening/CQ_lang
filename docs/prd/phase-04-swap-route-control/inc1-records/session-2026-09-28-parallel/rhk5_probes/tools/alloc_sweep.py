#!/usr/bin/env python3
"""alloc_sweep.py CQ_OPT CQ_OPT_DEBUGALLOC — the once-per-bead allocator sweep.

Every ir-pass/test/*.ll through plain `cq-opt` and through `cq-opt-debugalloc` with
CQ_OPT_DEBUG_ALLOC=lifo and =nofree; exit code, stdout sha-256 and the first `error:`
line must agree across all three. A disagreement is a stale-key / use-after-free
candidate (bd 8e5r class). Denominator printed first; 4 workers. A BOUNDARY CONTROL
runs first: an unknown CQ_OPT_DEBUG_ALLOC value must make the driver exit 2 (proving
the variable is read), and a 0-byte module is refused."""
import glob
import hashlib
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
OPT, DA = sys.argv[1], sys.argv[2]


def run(binary, f, mode):
    env = dict(os.environ)
    if mode is None:
        env.pop('CQ_OPT_DEBUG_ALLOC', None)
    else:
        env['CQ_OPT_DEBUG_ALLOC'] = mode
    p = subprocess.run([binary, '-passes=cq-lowering', '-S', f], capture_output=True, env=env,
                       timeout=600)
    err = [l for l in p.stderr.decode(errors='replace').splitlines() if 'error:' in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split('error:', 1)[1].strip() if err else '')


files = sorted(glob.glob(W + '/ir-pass/test/*.ll'))
files = [f for f in files if os.path.getsize(f) > 0]
ctl = run(DA, files[0], 'BOGUS')
print(f'boundary control: CQ_OPT_DEBUG_ALLOC=BOGUS -> exit {ctl[0]} (must be 2)', flush=True)
if ctl[0] != 2:
    sys.exit('!! the debug allocator does not read its variable — refusing to measure')
print(f'denominator: {len(files)} fixtures', flush=True)


def one(f):
    return f, run(OPT, f, None), run(DA, f, 'lifo'), run(DA, f, 'nofree')


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, files))
bad = [(f, a, b, c) for f, a, b, c in res if not (a == b == c)]
print(f'disagreements: {len(bad)} of {len(res)}')
for f, a, b, c in bad:
    print(f'  {os.path.basename(f)}\tplain={a}\tlifo={b}\tnofree={c}')
