#!/usr/bin/env python3
"""census2.py BIN LIST OUT : run BIN on every module in LIST with both census levers
(CQ_DEADARG_DBG, CQ_DEADCONE_DBG) and record which modules the round-2 machinery
touched (an argument drop, or a dead-cone deletion by any stage), with the census
lines. Positive control first: a module known to fire must be listed, a module known
not to must not — else the census itself is broken and the run aborts."""
import concurrent.futures as cf
import os
import subprocess
import sys

BIN, LIST, OUT = sys.argv[1:4]
files = [l.strip() for l in open(LIST) if l.strip()]
env = dict(os.environ, CQ_DEADARG_DBG="1", CQ_DEADCONE_DBG="1")


def one(f):
    r = subprocess.run([BIN, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"], capture_output=True, text=True, env=env)
    if r.returncode not in (0, 1):
        return f, None, f"RC{r.returncode}"
    lines = [l for l in r.stderr.splitlines() if l.startswith(("CQ_DEADARG_DBG", "CQ_DEADCONE_DBG"))]
    return f, lines, ""


W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test/"
pos = W + "spec_accept_dropped_arg_boolsel.ll"
neg = W + "lowering_basic.ll"
p = one(pos)
n = one(neg)
if not p[1] or n[1]:
    raise SystemExit(f"CENSUS BROKEN: positive={p[1]} negative={n[1]}")
res = []
with cf.ThreadPoolExecutor(8) as ex:
    for f, lines, err in ex.map(one, files):
        res.append((f, lines, err))
fired = [(f, l) for f, l, e in res if l]
bad = [(f, e) for f, l, e in res if e]
with open(OUT, "w") as o:
    o.write(f"denominator={len(files)} fired={len(fired)} toolfail={len(bad)}\n")
    for f, l in fired:
        o.write(f + "\t" + " | ".join(l) + "\n")
    for f, e in bad:
        o.write(f + "\t" + e + "\n")
print(f"denominator={len(files)} fired={len(fired)} toolfail={len(bad)}")
