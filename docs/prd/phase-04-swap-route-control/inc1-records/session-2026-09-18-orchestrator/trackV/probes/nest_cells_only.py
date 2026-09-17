#!/usr/bin/env python3
"""nest_cells_only.py — run ONLY the 23 bd `vsr6` NESTED-LOOP cells.

The implementer's inner loop, not a gate (PROTOCOL §6.1: the full
`e2e-loop-twin-matrix` is announced and run once, at the end). It stubs
`cells_of_matrix()` to `nest_cells()` and calls `main()` with `--out`, so the
verdicts come out of the SAME code path the gate uses — verdict classification,
boundary controls and all — rather than out of a second spelling of it.

⚠ The BOUNDARY CONTROLS still run, which is deliberate: `q_nestinline` is this
axis's control and its `void`-surface pin has to be MEASURED before it can be
written down. Until it is in `SURFACE_CONTROL_VERDICTS`, the run reports it as
`BOUNDARY CONTROL has NO PINNED VERDICT` and names the measured value — which is
the loop by which the pin is obtained honestly instead of guessed.

⚠ THE `if __name__` GUARD IS LOAD-BEARING, not style. `loop_twin_matrix` uses a
ProcessPoolExecutor, and on macOS Python 3.11 that means SPAWN: each child
re-imports the parent's `__main__`. Without the guard every child re-entered this
driver, re-parsed a truncated argv, printed an argparse usage block and died —
`BrokenProcessPool`, measured, 1.5 s, zero cells. A harness that dies is the
lucky case; the same shape that reports a tidy zero is the `checked 0` hole.

Usage (paths as the ctest entry spells them):

    python3 nest_cells_only.py <BUILD> <REPO> <OUT.tsv>
"""
import os
import sys


def main():
    build, repo = sys.argv[1], sys.argv[2]
    out = sys.argv[3] if len(sys.argv) > 3 else "/dev/stdout"
    sys.path.insert(0, os.path.join(repo, "tools"))
    import loop_twin_matrix as M

    M.cells_of_matrix = M.nest_cells
    os.environ.setdefault("CQ_LD",
                          os.path.join(build, "tests", "e2e", "cq_link.sh"))
    sys.argv = [
        "loop_twin_matrix",
        "--clang", "/usr/local/opt/llvm@19/bin/clang",
        "--opt", os.path.join(build, "ir-pass", "cq-opt"),
        "--plugin", os.path.join(build, "ir-pass", "libCQPass.so"),
        "--include", os.path.join(repo, "include"),
        "--runtime", os.path.join(build, "runtime", "libcq_runtime.a"),
        "--templates", os.path.join(build, "runtime", "libcq_templates.a"),
        "--phi-surface", "void", "--jobs", "4",
        "--expected", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                   "nest_expected_stub.txt"),
        "--out", out,
    ]
    return M.main()


if __name__ == "__main__":
    sys.exit(main())
