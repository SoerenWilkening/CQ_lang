#!/usr/bin/env python3
"""Corpus A/B: run every module in the given file list through a REFERENCE and a
SUBJECT cq-opt and classify each mover.

  ab_sweep.py REF SUBJECT LISTFILE [--null]

Compared per module: exit code, sha256 of stdout (the lowered IR), and the first
`error:` line's message. Classification of a mover:
  A->D   ref exit 0, subject non-zero
  D->A   ref non-zero, subject exit 0
  DIAG   both non-zero, first error message differs
  STREAM both exit 0, lowered IR differs
  OTHER  anything else (e.g. both non-zero with different exit codes, same msg)
Prints the denominator FIRST and every mover. With --null BOTH binaries are run
twice over the full list (REF vs REF and SUBJECT vs SUBJECT), each null control
is printed with its denominator, and the script refuses to report if either is
non-zero.

⚠ Fixed 2026-09-26 (bd 9bhg Rule-13 r1B F-9B-5): until then `--null` ran only
the REF twice, although this docstring said the SUBJECT. A reference-only null
control cannot see a subject whose verdicts vary from run to run (the
dangling-key allocator lottery, bd 8e5r). Every "null 0" cited before the fix
measured REF stability only.
"""
import hashlib
import pathlib
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

REF, SUB, LST = sys.argv[1], sys.argv[2], sys.argv[3]
files = [pathlib.Path(l.strip()) for l in open(LST) if l.strip()]


def run(b, f):
    r = subprocess.run([b, "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True)
    err = ""
    for l in r.stderr.decode(errors="replace").splitlines():
        if "error:" in l:
            err = l.split("error:", 1)[1]
            # drop the "<file>:<line>:<col>:" location prefix variations
            err = err.strip()
            break
    return r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16], err


def sweep(b):
    with ThreadPoolExecutor(8) as ex:
        return list(ex.map(lambda f: run(b, f), files))


def classify(r, n):
    if r == n:
        return None
    if r[0] == 0 and n[0] != 0:
        return "A->D"
    if r[0] != 0 and n[0] == 0:
        return "D->A"
    if r[0] == 0 and n[0] == 0:
        return "STREAM"
    if r[2] != n[2]:
        return "DIAG"
    return "OTHER"


print(f"denominator: {len(files)} modules")
if "--null" in sys.argv:
    a = sweep(REF)
    b = sweep(REF)
    null_ref = sum(classify(x, y) is not None for x, y in zip(a, b))
    print(f"null control (REF vs REF, full list): {null_ref} of {len(files)} movers")
    c = sweep(SUB)
    d = sweep(SUB)
    null_sub = sum(classify(x, y) is not None for x, y in zip(c, d))
    print(f"null control (SUBJECT vs SUBJECT, full list): {null_sub} of {len(files)} movers")
    if null_ref or null_sub:
        print("NULL CONTROL FAILED — not reporting")
        sys.exit(2)
    ref, new = a, c
else:
    ref = sweep(REF)
    new = sweep(SUB)
movers = [(f, r, n, classify(r, n)) for f, r, n in zip(files, ref, new)
          if classify(r, n)]
counts = {}
for *_, k in movers:
    counts[k] = counts.get(k, 0) + 1
print(f"movers: {len(movers)} " + " ".join(f"{k}={v}" for k, v in sorted(counts.items())))
for f, r, n, k in movers:
    line = f"  {k:6} {f.name}: ref rc={r[0]} sub rc={n[0]}"
    if k in ("DIAG", "A->D", "D->A", "OTHER"):
        line += f"\n         ref: {r[2][:140]}\n         sub: {n[2][:140]}"
    print(line)
