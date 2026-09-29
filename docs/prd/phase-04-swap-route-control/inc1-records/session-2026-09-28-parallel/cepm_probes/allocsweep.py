#!/usr/bin/env python3
"""allocsweep.py LISTFILE OUT — the allocator sweep: every module in LISTFILE through plain
`build/ir-pass/cq-opt` and through `build/ir-pass/cq-opt-debugalloc` under
CQ_OPT_DEBUG_ALLOC=lifo and =nofree (ir-pass/tools/cq_debug_alloc.cpp); exit code, stdout
sha-256 and first `error:` line must agree across the three. 4 workers. Prints the
denominator and every disagreement."""
import hashlib
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
PLAIN = W + "/build/ir-pass/cq-opt"
DBG = W + "/build/ir-pass/cq-opt-debugalloc"
files = [l.strip() for l in open(sys.argv[1]) if l.strip()]


def run(binary, f, mode):
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None)
    if mode:
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    try:
        p = subprocess.run([binary, "-passes=cq-lowering", "-S", f], capture_output=True,
                           env=env, timeout=600)
    except subprocess.TimeoutExpired:
        return ("TIMEOUT", "", "")
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")


def one(f):
    return f, run(PLAIN, f, None), run(DBG, f, "lifo"), run(DBG, f, "nofree")


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, files))
bad = [r for r in res if not (r[1] == r[2] == r[3])]
with open(sys.argv[2], "w") as o:
    o.write(f"denominator: {len(res)} modules; plain vs lifo vs nofree disagreements: {len(bad)}\n")
    for f, a, b, c in bad:
        o.write(f"{os.path.basename(f)}\n  plain={a}\n  lifo={b}\n  nofree={c}\n")
print(open(sys.argv[2]).read().splitlines()[0])
