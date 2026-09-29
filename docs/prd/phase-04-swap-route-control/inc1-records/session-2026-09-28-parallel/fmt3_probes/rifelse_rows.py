#!/usr/bin/env python3
"""fmt3 round 2 — the verdict ROWS of sub-grid E1 (the 24 `rifelse` crossings), computed with
tools/loop_twin_matrix.py's OWN `ry_cells()`, `run_cell` and `verdict()` and printed in the exact
`%-24s %s` format `--out` / `--regenerate` write — so the 23 NEW rows can be added to the committed
expected table BY HAND (never `--regenerate`: bd gfsk) and every other row stays untouched.
A cell whose verdict carries a failure report (a divergence / harness error) is printed with
`!!` and must NOT be blessed."""
import os, sys, types, concurrent.futures
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b"
sys.path.insert(0, W + "/tools")
import loop_twin_matrix as M
cfg = types.SimpleNamespace(clang="/usr/local/opt/llvm@19/bin/clang", opt=W + "/build/ir-pass/cq-opt",
    plugin=W + "/build/ir-pass/libCQPass.so", include=W + "/include",
    runtime=W + "/build/runtime/libcq_runtime.a", templates=W + "/build/runtime/libcq_templates.a",
    ld=W + "/build/tests/e2e/cq_link.sh", phi_surface="void")
def main():
    cells = [c for c in M.ry_cells() if c[1] == M.RY_IFELSE_REGION]
    assert len(cells) == 24, len(cells)
    bad = 0
    with concurrent.futures.ProcessPoolExecutor(max_workers=3) as ex:
        res = list(ex.map(M._run_cell_star, [(cfg, c) for c in cells]))
    rows = {}
    for name, rolled, unrolled in res:
        v, rep = M.verdict(name, rolled, unrolled)
        rows[name] = v
        if rep:
            bad += 1
            print("!! %s %s | %s" % (name, v, rep.splitlines()[0]), file=sys.stderr)
    for n in sorted(rows):
        print("%-24s %s" % (n, rows[n]))
    print("# %d cells, %d with a failure report" % (len(rows), bad), file=sys.stderr)

if __name__ == '__main__':
    main()
