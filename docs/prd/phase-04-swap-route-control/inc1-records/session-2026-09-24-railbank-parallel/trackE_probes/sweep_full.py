#!/usr/bin/env python3
"""Exit-code + stdout-sha sweep of every ir-pass/test/*.ll: this build vs a
reference binary (arg 1). Null control first (the reference against itself on
the first 40 files, both fields). Prints denominators and every mover."""
import hashlib
import pathlib
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = pathlib.Path(__file__).resolve().parent.parent
NEW = W / "build/ir-pass/cq-opt"
REF = pathlib.Path(sys.argv[1])
files = sorted((W / "ir-pass/test").glob("*.ll"))


def run(b, f):
    r = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                       capture_output=True)
    err = [l for l in r.stderr.decode(errors="replace").splitlines() if "error:" in l][:1]
    return r.returncode, hashlib.sha256(r.stdout).hexdigest()[:16], "".join(err).split(": ")[-1]


with ThreadPoolExecutor(8) as ex:
    a = list(ex.map(lambda f: run(REF, f), files[:40]))
    b = list(ex.map(lambda f: run(REF, f), files[:40]))
null = sum(x != y for x, y in zip(a, b))
print(f"null control: {null} of {len(a)} movers (exit+stdout+first error line)")
with ThreadPoolExecutor(8) as ex:
    ref = list(ex.map(lambda f: run(REF, f), files))
    new = list(ex.map(lambda f: run(NEW, f), files))
movers = [(f.name, r, n) for f, r, n in zip(files, ref, new) if r != n]
print(f"swept {len(files)} fixtures; {len(movers)} mover(s)")
for name, r, n in movers:
    kind = "EXIT " if r[0] != n[0] else ("STDOUT" if r[1] != n[1] else "DIAG ")
    print(f"  {kind} {name}: ref rc={r[0]} new rc={n[0]}" + (f"  [{r[2]}] -> [{n[2]}]" if kind == "DIAG " else ""))
