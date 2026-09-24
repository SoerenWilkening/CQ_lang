#!/usr/bin/env python3
"""Compile every tests/e2e/*.c (no -DCASE) at -O1 once; lower with this build and
the reference; print exit/diag movers. Matrix sources compile their default CASE."""
import pathlib
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
W = pathlib.Path(__file__).resolve().parent.parent
NEW = W / "build/ir-pass/cq-opt"
REF = pathlib.Path(sys.argv[1])
L = "/usr/local/opt/llvm@19/bin/clang"
tmp = pathlib.Path(tempfile.mkdtemp())
srcs = sorted((W / "tests/e2e").glob("*.c"))


def one(c):
    s1 = tmp / (c.stem + ".ll")
    r = subprocess.run([L, f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
                        str(c), "-o", str(s1)], capture_output=True)
    if r.returncode:
        return c.name, None, None
    out = []
    for b in (REF, NEW):
        p = subprocess.run([str(b), "-passes=cq-lowering", "-S", str(s1), "-o", "/dev/null"],
                           capture_output=True, text=True)
        m = re.search(r"error: .*?: (cq [^\n]*)", p.stderr)
        out.append((p.returncode, m.group(1) if m else ""))
    return c.name, out[0], out[1]


with ThreadPoolExecutor(8) as ex:
    res = list(ex.map(one, srcs))
ok = [r for r in res if r[1] is not None]
print(f"compiled {len(ok)} of {len(srcs)} e2e sources")
mv = [r for r in ok if r[1] != r[2]]
print(f"{len(mv)} mover(s)")
for n, a, b in mv:
    print(f"  {n}: ref {a} -> new {b}")
