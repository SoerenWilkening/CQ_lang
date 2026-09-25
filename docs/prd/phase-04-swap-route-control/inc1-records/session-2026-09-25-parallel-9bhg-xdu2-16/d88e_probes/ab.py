#!/usr/bin/env python3
"""ab.py REF SUB LISTFILE OUT — corpus A/B for bd d88e.

Per module: exit code, sha256 of stdout (lowered IR) and of the full stderr, and
the first `error:` message. NULL CONTROL FIRST (REF vs REF over the whole list;
refuses to report if it moves anything), then REF vs SUB. Prints the denominator
before anything else and every mover with its class:
  A->D, D->A, DIAG (both decline, first message differs), STDERR (both decline,
  same first message, stderr differs), STREAM (both accept, IR differs), OTHER.
"""
import hashlib
import pathlib
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

REF, SUB, LST, OUT = sys.argv[1:5]
files = [pathlib.Path(l.strip()) for l in open(LST) if l.strip()]


def run(b, f):
    r = subprocess.run([b, "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True)
    err = ""
    for l in r.stderr.decode(errors="replace").splitlines():
        if "error:" in l:
            err = l.split("error:", 1)[1].strip()
            break
    return (r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16],
            hashlib.sha256(r.stderr).hexdigest()[:16], err)


def sweep(b):
    with ThreadPoolExecutor(6) as ex:
        return list(ex.map(lambda f: run(b, f), files))


def classify(r, n):
    if r == n:
        return None
    if r[0] == 0 and n[0] != 0:
        return "A->D"
    if r[0] != 0 and n[0] == 0:
        return "D->A"
    if r[0] == 0 and n[0] == 0:
        return "STREAM" if r[1] != n[1] else "OTHER"
    if r[3] != n[3]:
        return "DIAG"
    if r[2] != n[2]:
        return "STDERR"
    return "OTHER"


out = open(OUT, "w")


def say(s):
    print(s)
    out.write(s + "\n")


empty = [f for f in files if f.stat().st_size < 200]
say(f"denominator: {len(files)} modules ({len(empty)} under 200 bytes)")
a = sweep(REF)
b = sweep(REF)
nullc = [f for f, x, y in zip(files, a, b) if classify(x, y)]
say(f"null control (REF vs REF): {len(nullc)} of {len(files)} movers")
if nullc:
    for f in nullc:
        say(f"  NULL-MOVER {f}")
    say("NULL CONTROL FAILED - not reporting")
    sys.exit(2)
n = sweep(SUB)
movers = [(f, r, s, classify(r, s)) for f, r, s in zip(files, a, n) if classify(r, s)]
counts = {}
for *_, k in movers:
    counts[k] = counts.get(k, 0) + 1
say(f"movers (REF vs SUB): {len(movers)} of {len(files)} " +
    " ".join(f"{k}={v}" for k, v in sorted(counts.items())))
acc = sum(1 for r in a if r[0] == 0)
say(f"REF accepts {acc}, declines {len(files) - acc}")
for f, r, s, k in movers:
    say(f"  {k:6} {f}: ref rc={r[0]} [{r[3][:110]}] -> sub rc={s[0]} [{s[3][:110]}]")
