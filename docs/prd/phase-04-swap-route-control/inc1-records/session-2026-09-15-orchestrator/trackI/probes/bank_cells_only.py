#!/usr/bin/env python3
"""bank_cells_only.py — measure JUST the 21 bank cells (bd rpkr).

`loop_twin_matrix.py` has no `--filter`, and adding one would be a change to the
gate rather than to the axis. This driver imports the module and calls its OWN
`run_cell` / `verdict` — never a re-spelling of either (Rule 14) — so the rows it
prints are exactly the rows the gate will compare against, produced by the same
code path. It is a PROBE, not a gate: the committed `e2e-loop-twin-matrix` entry
is what measures.

    python3 bank_cells_only.py --clang ... --opt ... --plugin ... --include ...
                               --runtime ... --templates ... [--jobs 6]

Exits non-zero if it produced no rows — a driver that prints nothing and returns
0 is the `checked 0` hole.
"""

import argparse
import concurrent.futures
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", "..",
                                     "..", "tools"))
sys.path.insert(0, TOOLS)
import loop_twin_matrix as M  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    for f in ("clang", "opt", "plugin", "include", "runtime", "templates"):
        ap.add_argument("--" + f, required=True)
    ap.add_argument("--jobs", type=int, default=6)
    # The bd dgn5 link wrapper, same default as the gate's.
    ap.add_argument("--ld", default=os.environ.get("CQ_LD", ""))
    ap.add_argument("--phi-surface", default="void")
    ap.add_argument("--out", default="")
    cfg = ap.parse_args()

    cells = M.bank_cells()
    if not cells:
        print("REFUSED: bank_cells() produced NO cells.")
        return 2
    rows = []
    with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
        for name, rolled, unrolled in ex.map(
                M._run_cell_star, [(cfg, c) for c in cells]):
            v, report = M.verdict(name, rolled, unrolled)
            rows.append((name, v, report))
    rows.sort()
    for name, v, report in rows:
        print("%-34s %s" % (name, v))
        if report:
            print("    HARD: %s" % report.splitlines()[0])
    if cfg.out:
        with open(cfg.out, "w") as f:
            for name, v, _ in rows:
                f.write("%-24s %s\n" % (name, v))
    print("\n%d bank cell(s)" % len(rows))
    return 0 if rows else 2


if __name__ == "__main__":
    sys.exit(main())
