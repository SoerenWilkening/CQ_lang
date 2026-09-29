#!/usr/bin/env python3
"""Allocator sweep (once per bead, the brief's final-round item): every
ir-pass/test/*.ll through plain `cq-opt` and through `cq-opt-debugalloc` with
CQ_OPT_DEBUG_ALLOC=<mode> (lifo | nofree). Exit code, stdout sha-256[:16] and the
first `error:` line must agree. Prints the denominator first; ≤4 workers.

  allocsweep.py <cq-opt> <cq-opt-debugalloc> <mode>
"""
import glob
import hashlib
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82"
OPT, DBG, MODE = sys.argv[1], sys.argv[2], sys.argv[3]


def run(binary, f, env=None):
    p = subprocess.run([binary, "-passes=cq-lowering", "-S", f], capture_output=True,
                       timeout=600, env=env)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")


files = sorted(glob.glob(W + "/ir-pass/test/*.ll"))
print(f"denominator: {len(files)} fixtures  mode={MODE}", flush=True)
env = dict(os.environ, CQ_OPT_DEBUG_ALLOC=MODE)


def one(f):
    return f, run(OPT, f), run(DBG, f, env)


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, files))
bad = [(f, a, b) for f, a, b in res if a != b]
print(f"disagreements {len(bad)} of {len(res)}")
for f, a, b in bad:
    print(f"{os.path.basename(f)}\tplain={a}\tdebugalloc={b}")
