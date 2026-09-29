#!/usr/bin/env python3
"""ab_extra.py OPT_A OPT_B — the populations ab.py does not sweep but that run under
ctest: tools/railbank_twin_pairs/*.c (the railbank register-twin gate) and every
example/**/*.c present in the tree. Same comparison (exit, stdout sha, first error,
warning) and the same 0-byte refusal. Prints its denominator."""
import glob
import hashlib
import os
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
L = '/usr/local/opt/llvm@19/bin'
A, B = sys.argv[1], sys.argv[2]
T = tempfile.mkdtemp(prefix='rhk5abx')


def run(opt, s1):
    p = subprocess.run([opt, '-passes=cq-lowering', '-S', s1], capture_output=True, timeout=600)
    se = p.stderr.decode(errors='replace')
    err = [l for l in se.splitlines() if 'error:' in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split('error:', 1)[1].strip() if err else '', 'warning:' in se)


def one(c):
    s1 = os.path.join(T, os.path.basename(c) + '.s1.ll')
    r = subprocess.run([L + '/clang', '-I' + W + '/include', '-include', 'CQ.h', '-O1', '-emit-llvm',
                        '-S', '-Wno-everything', c, '-o', s1], capture_output=True)
    if r.returncode or not os.path.exists(s1) or os.path.getsize(s1) == 0:
        return c, None, None
    return c, run(A, s1), run(B, s1)


srcs = sorted(glob.glob(W + '/tools/railbank_twin_pairs/*.c') + glob.glob(W + '/example/**/*.c', recursive=True))
with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, srcs))
ok = [r for r in res if r[1] is not None]
mov = [r for r in ok if r[1] != r[2]]
print(f'denominator {len(srcs)} sources; {len(ok)} built; {len(srcs) - len(ok)} not buildable alone; movers {len(mov)}')
for c, a, b in mov:
    print(f'  {os.path.relpath(c, W)}\tA={a}\tB={b}')
