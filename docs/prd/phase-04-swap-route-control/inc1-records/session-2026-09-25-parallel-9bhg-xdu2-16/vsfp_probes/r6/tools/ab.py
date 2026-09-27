#!/usr/bin/env python3
"""Corpus A/B: run two cq-opt binaries over a list of .ll modules, compare
(exit code, stdout sha, stderr text). Prints the DENOMINATOR first and every mover
classified: A->D, D->A, DIAG (both decline, stderr differs), STREAM (both accept,
stdout differs), WARN (both accept, same stdout, stderr differs), CRASH (rc not in
{0,1}).
usage: ab.py BIN_A BIN_B LISTFILE OUTFILE [jobs]
"""
import concurrent.futures as cf
import hashlib
import subprocess
import sys

A, B, LIST, OUT = sys.argv[1:5]
J = int(sys.argv[5]) if len(sys.argv) > 5 else 8
files = [l.strip() for l in open(LIST) if l.strip()]


def run(binp, f):
    r = subprocess.run([binp, "-passes=cq-lowering", "-S", f, "-o", "-"],
                       capture_output=True)
    err = r.stderr.decode(errors="replace")
    return r.returncode, hashlib.sha256(r.stdout).hexdigest(), err, len(r.stdout)


def one(f):
    a = run(A, f)
    b = run(B, f)
    return f, a, b


def first_err(e):
    for l in e.splitlines():
        if "error:" in l:
            return l.split("error: ", 1)[-1][:160]
    return ""


rows = []
with cf.ThreadPoolExecutor(J) as ex:
    for f, a, b in ex.map(one, files):
        rows.append((f, a, b))
# INPUT GUARD (a run whose inputs were not found reports "0 movers" over the full
# denominator — measured once in this track with relative paths): refuse it.
bad = [f for f, a, b in rows if "No such file" in a[2] or "Could not open" in a[2] or "No such file" in b[2]]
if bad:
    raise SystemExit(f"INPUT ERROR: {len(bad)} of {len(files)} modules unreadable, e.g. {bad[0]}")

cls = {}
with open(OUT, "w") as o:
    o.write(f"denominator={len(files)} A={A} B={B}\n")
    for f, a, b in rows:
        k = None
        if a[0] not in (0, 1) or b[0] not in (0, 1):
            if (a[0], a[1]) != (b[0], b[1]):
                k = "CRASH"
        elif a[0] == 0 and b[0] != 0:
            k = "A->D"
        elif a[0] != 0 and b[0] == 0:
            k = "D->A"
        elif a[0] != 0 and b[0] != 0:
            if a[2] != b[2]:
                k = "DIAG"
        else:
            if a[1] != b[1]:
                k = "STREAM"
            elif a[2] != b[2]:
                k = "WARN"
        if k:
            cls[k] = cls.get(k, 0) + 1
            o.write(f"{k}\t{f}\tA_rc={a[0]} B_rc={b[0]}\tA:{first_err(a[2])}\tB:{first_err(b[2])}\n")
    o.write("summary " + " ".join(f"{k}={v}" for k, v in sorted(cls.items())) + "\n")
print(f"denominator={len(files)} movers={sum(cls.values())} " + " ".join(f"{k}={v}" for k, v in sorted(cls.items())))
