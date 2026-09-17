#!/usr/bin/env python3
"""seed_fidelity.py — how close is the GENERATED nested cell to the COMMITTED
probe it was seeded from?

bd `test_C_libtooling-vsr6`'s brief asks for byte identity against
`$PREV/loopfix/probes/n{1,2,3}*.c` and says, in the same sentence, that if the
generator cannot reach it *the committed probe is the tie-breaker and you say
so*. This is the measurement behind that sentence: it prints the normalised
unified diff for each of the eleven seeds that has a generated counterpart, so
the report quotes a diff rather than an adjective.

NORMALISATION, and each clause is a difference the twin matrix imposes on EVERY
cell in the file rather than something this axis chose:

  * whitespace — `_wrap` writes the enclosed families at the subject loop's own
    indentation (an enclosing loop opens at 4 and the subject `for` stays at 4),
    which is cosmetic and is not a program difference;
  * comments and blank lines — the probes carry their provenance headers;
  * `#include "CQ.h"` vs `#include <math.h>` + `volatile int off = 3;` — the
    matrix's fixed `HDR`, which every one of the 382 cells carries;
  * `int main(void) { return slice(); }` vs the matrix's
    `int main(void){(void)slice();return 0;}`.

Everything that survives normalisation is a REAL difference between the seed and
the cell, and is reported as one. It is not a gate (there is nothing to gate: the
cells' verdicts are pinned in the expected table); it is the evidence for
IMPL_V §2.
"""
import difflib
import importlib.util
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = "/Users/sorenwilkening/Desktop/Projects/CQ_lang"
SEEDS = os.path.join(
    REPO, "docs/prd/phase-04-swap-route-control/inc1-records",
    "session-2026-09-15-orchestrator/loopfix/probes")

# seed basename (without .c) -> the cell whose ROLLED source it is seeded from.
PAIRS = {
    "n1_nested_marked_inner":   ("none", "l2bd", "none", "none", "l2im"),
    "n2_nested_unmarked_inner": ("none", "l2bd", "none", "none", "l2iu"),
    "n3_nested_iic_inner":      ("none", "l2bd", "none", "none", "l2ic"),
    "r1_triple_nest_mid_rail":  ("none", "l2d3d", "none", "none", "l2im"),
    "r2_outer_marked_inner_rail": ("none", "l2invd", "none", "none", "none"),
    "r3_nested_cmp_rail_outer": ("none", "l2cd", "none", "none", "l2im"),
    "r5_sibling_loops_one_marked": ("none", "l2sibd", "none", "none", "none"),
    "a9_nested_loop":           ("none", "l2n", "none", "none", "l2iu"),
}
# The UNROLLED twin of each, where the seed ships one.
TWINS = {k + "_un": v for k, v in PAIRS.items()
         if os.path.exists(os.path.join(SEEDS, k + "_un.c"))}

_COMMENT = re.compile(r"/\*.*?\*/|//[^\n]*", re.S)


def norm(text):
    text = _COMMENT.sub("", text)
    out = []
    for line in text.splitlines():
        line = " ".join(line.split())
        if not line:
            continue
        if line.startswith("#include"):
            continue
        if line.startswith("volatile int off"):
            continue
        if line.startswith("int main(void)"):
            continue
        out.append(line)
    return out


def load(tools):
    spec = importlib.util.spec_from_file_location(
        "ltm", os.path.join(tools, "loop_twin_matrix.py"))
    m = importlib.util.module_from_spec(spec)
    sys.modules["ltm"] = m
    spec.loader.exec_module(m)
    return m


def main():
    if len(sys.argv) != 3 or sys.argv[1] != "--tools":
        print("usage: seed_fidelity.py --tools <DIR containing "
              "loop_twin_matrix.py>")
        return 2
    M = load(sys.argv[2])
    total_diff = 0
    for label, table, which in (("ROLLED", PAIRS, 0), ("UNROLLED", TWINS, 1)):
        for seed, cell in sorted(table.items()):
            path = os.path.join(SEEDS, seed + ".c")
            if not os.path.exists(path):
                print("%-34s %-30s SEED ABSENT" % (seed, M.cell_name(cell)))
                continue
            got = M.sources(*cell, surface="void")[which]
            a, b = norm(open(path).read()), norm(got)
            d = [l for l in difflib.unified_diff(a, b, "seed", "cell",
                                                 lineterm="", n=0)
                 if l[:1] in "+-" and not l.startswith(("---", "+++"))]
            total_diff += len(d)
            print("%s  %-32s %-32s %d normalised line(s) differ"
                  % (label[:3], seed, M.cell_name(cell), len(d)))
            for l in d:
                print("        %s" % l)
    print("seed_fidelity: %d normalised differing line(s) in total" % total_diff)
    return 0


if __name__ == "__main__":
    sys.exit(main())
