#!/usr/bin/env python3
"""k_readshape.py — MEASURE the fact the BANK axis's two read shapes rest on.

bd `test_C_libtooling-rpkr`. The claim in `tools/loop_twin_matrix.py`'s BANK AXIS
block is that `clang -O1` scalarises the UNROLLED twin of a `kflat` cell
COMPLETELY (its constant subscripts are SROA-able) and scalarises NEITHER side of
a `kloop` cell (its read loop subscripts dynamically). That is a measurement, not
a design preference, so it is taken here from the GENERATED sources themselves —
never from a hand-written lookalike, which is how a number ends up describing a
program that ships nowhere.

    python3 k_readshape.py --clang /usr/local/opt/llvm@19/bin/clang \
                           --include <repo>/include

Prints, per cell and side: array `alloca`s, `getelementptr`s, and whether the
stage-1 module still contains an aggregate at all. Exits non-zero if it measured
nothing.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", "..",
                                     "..", "tools"))
sys.path.insert(0, TOOLS)
import loop_twin_matrix as M  # noqa: E402

CELLS = [("none", "kprep", "none", "none", "kflat"),
         ("none", "kprep", "none", "none", "kloop"),
         ("none", "kiprep", "none", "none", "kflat"),
         ("none", "k2b", "none", "none", "kloop")]


def stage1(clang, inc, src, work, name):
    c = os.path.join(work, name + ".c")
    ll = os.path.join(work, name + ".ll")
    open(c, "w").write(src)
    r = subprocess.run([clang, "-I", inc, "-include", "CQ.h", "-O1",
                        "-emit-llvm", "-S", c, "-o", ll],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None, r.stderr
    return open(ll).read(), None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clang", required=True)
    ap.add_argument("--include", required=True)
    cfg = ap.parse_args()
    work = tempfile.mkdtemp(prefix="kread_")
    rows = 0
    print("%-34s %-9s %6s %6s  %s"
          % ("cell", "side", "alloca", "gep", "aggregate survives -O1?"))
    for cell in CELLS:
        name = M.cell_name(cell)
        rolled, unrolled = M.sources(*cell, surface="void")
        for side, src in (("rolled", rolled), ("unrolled", unrolled)):
            ll, err = stage1(cfg.clang, cfg.include, src, work,
                             name + "_" + side)
            if ll is None:
                print("%-34s %-9s  STAGE-1 FAILED: %s"
                      % (name, side, err.strip().splitlines()[:1]))
                continue
            alloca = len(re.findall(r"alloca \[\d+ x ", ll))
            gep = ll.count("getelementptr")
            print("%-34s %-9s %6d %6d  %s"
                  % (name, side, alloca, gep, "YES" if alloca else "no (SROA)"))
            rows += 1
    if not rows:
        print("REFUSED: measured nothing (exit 2, never 0).")
        return 2
    print("\n%d side(s) measured" % rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
