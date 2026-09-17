#!/usr/bin/env python3
"""source_identity.py — PROVE, never assert, that a new twin-matrix axis leaves
every pre-existing cell's generated C byte-identical.

Carried from `$PREV/trackI/probes/source_identity.py` (bd `rpkr`, the BANK axis)
with ONE change: the module under test is given by `--tools`, so the BASELINE can
be taken from a DIFFERENT checkout's `tools/` than the subject. Track I dumped
its baseline before editing its own copy; a worktree that starts from `main` can
instead read `main`'s copy directly, which removes the one way that discipline
can go wrong — a baseline taken from an already-edited file.

    python3 source_identity.py --tools <DIR> --dump  <out.tsv>   # the baseline
    python3 source_identity.py --tools <DIR> --check <out.tsv>   # the subject

`--check` exits non-zero on ANY changed row and on ANY missing row; NEW rows are
reported and are not a failure (that is what adding an axis means). It exits
non-zero when the baseline is EMPTY or the run produces NO cells — a prover that
reports `0 compared, 0 differ` is the `checked 0` hole (bd `jdec`).
"""
import argparse
import hashlib
import importlib.util
import os
import sys


def load(tools):
    spec = importlib.util.spec_from_file_location(
        "ltm_under_test", os.path.join(tools, "loop_twin_matrix.py"))
    m = importlib.util.module_from_spec(spec)
    sys.modules["ltm_under_test"] = m
    spec.loader.exec_module(m)
    return m


def rows(M):
    for cell in M.cells_of_matrix():
        name = M.cell_name(cell)
        for surface in ("register", "void"):
            r, u = M.sources(*cell, surface=surface)
            yield ("%s\t%s" % (name, surface),
                   hashlib.sha256(r.encode()).hexdigest()[:16],
                   hashlib.sha256(u.encode()).hexdigest()[:16])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tools", required=True)
    ap.add_argument("--dump")
    ap.add_argument("--check")
    a = ap.parse_args()
    M = load(a.tools)
    got = {k: (r, u) for k, r, u in rows(M)}
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
