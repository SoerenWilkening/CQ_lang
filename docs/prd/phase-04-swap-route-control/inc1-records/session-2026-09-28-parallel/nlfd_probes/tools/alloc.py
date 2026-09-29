#!/usr/bin/env python3
"""alloc.py CQ_OPT CQ_OPT_DEBUGALLOC — the allocator sweep over every ir-pass/test/*.ll:
plain cq-opt vs cq-opt-debugalloc with CQ_OPT_DEBUG_ALLOC=lifo and =nofree (the test-only
allocators that make a freed-and-reused key deterministic, ir-pass/tools/cq_debug_alloc.cpp).
Exit code, stdout sha-256 and first error line must agree across the three. Prints the
denominator and every disagreement. ≤4 workers."""
import glob
import hashlib
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295"
P, D = sys.argv[1], sys.argv[2]


def run(opt, f, mode=None):
    env = dict(os.environ)
    if mode:
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", f, "-o", "-"], capture_output=True, env=env,
                       timeout=900)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")


files = sorted(glob.glob(W + "/ir-pass/test/*.ll"))
print(f"denominator: {len(files)} fixtures  plain={P}  debugalloc={D}", flush=True)


def one(f):
    return f, run(P, f), run(D, f, "lifo"), run(D, f, "nofree")


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, files))
bad = [r for r in res if not (r[1] == r[2] == r[3])]
print(f"disagreements: {len(bad)} of {len(res)}")
for f, a, b, c in bad:
    print(f"{os.path.basename(f)}\tplain={a}\tlifo={b}\tnofree={c}")
