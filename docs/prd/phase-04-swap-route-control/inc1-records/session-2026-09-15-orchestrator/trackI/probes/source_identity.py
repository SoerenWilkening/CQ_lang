#!/usr/bin/env python3
"""source_identity.py — PROVE, never assert, that a new twin-matrix axis leaves
every pre-existing cell's generated C byte-identical.

The discipline is `tools/loop_twin_matrix.py`'s own: every axis added since the
C-1 rounds (`prehead`, `preloop`, `postloop`, `second`, `bcond`) claims in its
docstring that the older cells' source text is untouched, and every one of those
claims was PROVEN by hashing the generated sources before and after rather than
argued. bd `rpkr` (the BANK axis) is the sixth, and this is its prover.

    python3 source_identity.py --dump  <out.tsv>     # before the edit
    python3 source_identity.py --check <out.tsv>     # after it

`--check` exits non-zero on ANY changed row and on ANY missing row; NEW rows are
reported and are not a failure (that is what adding an axis means). It also
exits non-zero when the baseline is EMPTY or the run produces NO cells — a
prover that reports `0 compared, 0 differ` is the `checked 0` hole this session
is closing elsewhere (bd `jdec`), and it is not going to be re-opened here.
"""
import argparse
import hashlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", "..",
                                     "..", "tools"))
sys.path.insert(0, TOOLS)
import loop_twin_matrix as M  # noqa: E402


def rows():
    for cell in M.cells_of_matrix():
        name = M.cell_name(cell)
        for surface in ("register", "void"):
            r, u = M.sources(*cell, surface=surface)
            yield ("%s\t%s" % (name, surface),
                   hashlib.sha256(r.encode()).hexdigest()[:16],
                   hashlib.sha256(u.encode()).hexdigest()[:16])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump")
    ap.add_argument("--check")
    a = ap.parse_args()
    got = {k: (r, u) for k, r, u in rows()}
    if not got:
        print("REFUSED: cells_of_matrix() produced NO cells — a prover with no "
              "subject proves nothing (exit 2, never 0).")
        return 2
    if a.dump:
        with open(a.dump, "w") as f:
            for k in sorted(got):
                f.write("%s\t%s\t%s\n" % (k, got[k][0], got[k][1]))
        print("dumped %d cell/surface pair(s) to %s" % (len(got), a.dump))
        return 0
    want = {}
    with open(a.check) as f:
        for line in f:
            p = line.rstrip("\n").split("\t")
            want["%s\t%s" % (p[0], p[1])] = (p[2], p[3])
    if not want:
        print("REFUSED: the baseline %s is EMPTY — nothing to compare against "
              "(exit 2, never 0)." % a.check)
        return 2
    moved = [k for k in want if k not in got or got[k] != want[k]]
    new = sorted(set(got) - set(want))
    print("source_identity: %d baseline pair(s), %d in this run, %d NEW, "
          "%d MOVED" % (len(want), len(got), len(new), len(moved)))
    for k in new:
        print("    NEW   %s" % k.replace("\t", "  "))
    for k in sorted(moved):
        print("    MOVED %s\n        was %s\n        now %s"
              % (k.replace("\t", "  "), want[k],
                 got.get(k, ("<absent>", "<absent>"))))
    return 1 if moved else 0


if __name__ == "__main__":
    sys.exit(main())
