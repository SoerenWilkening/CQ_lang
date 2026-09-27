#!/usr/bin/env python3
"""Census: which modules does the dead-arg drop touch? usage: census.py BIN LIST OUT"""
import concurrent.futures as cf
import os
import subprocess
import sys

BIN, LIST, OUT = sys.argv[1:4]
files = [l.strip() for l in open(LIST) if l.strip()]
env = dict(os.environ, CQ_DEADARG_DBG="1")


def one(f):
    r = subprocess.run([BIN, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"],
                       capture_output=True, env=env)
    e = r.stderr.decode(errors="replace")
    drops = [l for l in e.splitlines() if l.startswith("CQ_DEADARG_DBG")]
    return f, r.returncode, drops


with cf.ThreadPoolExecutor(10) as ex:
    res = list(ex.map(one, files))
n = 0
with open(OUT, "w") as o:
    o.write(f"denominator={len(files)}\n")
    for f, rc, d in res:
        if d:
            n += 1
            o.write(f"{f}\trc={rc}\t{' | '.join(x.split(': ',1)[1] for x in d)}\n")
print(f"denominator={len(files)} touched={n}")
