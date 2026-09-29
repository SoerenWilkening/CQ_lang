#!/usr/bin/env python3
"""Corpus A/B: ORACLE vs SUBJECT over a list of stage-1 .ll modules.
Usage: ab.py ORACLE SUBJECT LISTFILE [LABEL]
Per module: exit code, sha-256 of stdout (the lowered IR), first `error:` line.
NULL CONTROL FIRST: the SUBJECT is run TWICE over the whole list and the script
refuses to report movers if the two runs differ anywhere (a flaky subject would
make every mover suspect). Prints the denominator before anything else. 4 workers
(load discipline). A 0-byte module is reported and excluded (it would ACCEPT
through the passthrough early-out)."""
import hashlib
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

A, B, LIST = sys.argv[1], sys.argv[2], sys.argv[3]
LABEL = sys.argv[4] if len(sys.argv) > 4 else os.path.basename(LIST)
files = [l.strip() for l in open(LIST) if l.strip()]
empty = [f for f in files if not os.path.exists(f) or os.path.getsize(f) == 0]
files = [f for f in files if f not in empty]
print(f"[{LABEL}] denominator: {len(files)} modules ({len(empty)} missing/0-byte excluded)"
      f"  A={os.path.basename(A)}  B={os.path.basename(B)}", flush=True)
for f in empty:
    print(f"[{LABEL}] EXCLUDED (missing/0-byte): {f}")


def run(opt, f):
    try:
        p = subprocess.run([opt, "-passes=cq-lowering", "-S", f], capture_output=True, timeout=600)
    except subprocess.TimeoutExpired:
        return ("TIMEOUT", "", "")
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")


with ThreadPoolExecutor(4) as ex:
    b1 = list(ex.map(lambda f: run(B, f), files))
with ThreadPoolExecutor(4) as ex:
    b2 = list(ex.map(lambda f: run(B, f), files))
nullmov = [f for f, x, y in zip(files, b1, b2) if x != y]
print(f"[{LABEL}] NULL CONTROL (subject twice): {len(nullmov)} of {len(files)} differ", flush=True)
for f in nullmov:
    print(f"[{LABEL}] NULL-MOVER {f}")
if nullmov:
    print(f"[{LABEL}] REFUSING to report movers: the subject is not stable")
    sys.exit(2)
with ThreadPoolExecutor(4) as ex:
    a = list(ex.map(lambda f: run(A, f), files))
mov = [(f, x, y) for f, x, y in zip(files, a, b1) if x != y]
nA = sum(1 for x in a if x[0] == 0)
nB = sum(1 for y in b1 if y[0] == 0)
kinds = {}
for f, x, y in mov:
    k = ("D->A" if x[0] != 0 and y[0] == 0 else "A->D" if x[0] == 0 and y[0] != 0
         else "STRING" if x[0] != 0 else "STREAM")
    kinds[k] = kinds.get(k, 0) + 1
print(f"[{LABEL}] accepts A={nA} B={nB}; movers {len(mov)} of {len(files)}: {kinds}")
for f, x, y in mov:
    k = ("D->A" if x[0] != 0 and y[0] == 0 else "A->D" if x[0] == 0 and y[0] != 0
         else "STRING" if x[0] != 0 else "STREAM")
    print(f"[{LABEL}] {k}\t{f}\n    A={x}\n    B={y}")
