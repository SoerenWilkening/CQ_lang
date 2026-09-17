#!/usr/bin/env python3
"""nest_diverge_detail.py — the eight diverging `l2*` cells, in full.

A quarantine block may never be written from a REMEMBERED signature (IMPL_T2 §9;
`CLAUDE.md` L10), so this prints, for each diverging cell, the digest
`divergence_signature` computes, the first differing line pair, the per-side
counts and the whole unified diff — the evidence a quarantine entry's `reason`
has to be written from.

    python3 nest_diverge_detail.py <BUILD> <REPO> [cell ...]
"""
import os
import sys


def main():
    build, repo = sys.argv[1], sys.argv[2]
    only = set(sys.argv[3:])
    sys.path.insert(0, os.path.join(repo, "tools"))
    import difflib
    import loop_twin_matrix as M

    os.environ.setdefault("CQ_LD",
                          os.path.join(build, "tests", "e2e", "cq_link.sh"))

    class Cfg:
        clang = "/usr/local/opt/llvm@19/bin/clang"
        opt = os.path.join(build, "ir-pass", "cq-opt")
        plugin = os.path.join(build, "ir-pass", "libCQPass.so")
        include = os.path.join(repo, "include")
        runtime = os.path.join(build, "runtime", "libcq_runtime.a")
        templates = os.path.join(build, "runtime", "libcq_templates.a")
        ld = os.environ["CQ_LD"]
        phi_surface = "void"

    for cell in M.nest_cells():
        name = M.cell_name(cell)
        if only and name not in only:
            continue
        n, r, u = M.run_cell(Cfg, cell)
        v, _ = M.verdict(n, r, u)
        if not v.startswith("TRACE-DIVERGENCE"):
            continue
        d, rl, ul = M.divergence_signature(r.trace, u.trace)
        print("=" * 72)
        print("cell     %s" % n)
        print("digest   %s" % d)
        print("rolled   %s" % rl)
        print("unrolled %s" % ul)
        print("counts (_unc, cqrt_free, mints)  rolled %s over %d lines / "
              "unrolled %s over %d lines"
              % (M.counts(r.trace), len(r.trace.splitlines()),
                 M.counts(u.trace), len(u.trace.splitlines())))
        for line in difflib.unified_diff(r.trace.splitlines(),
                                         u.trace.splitlines(),
                                         fromfile="rolled", tofile="unrolled",
                                         lineterm="", n=2):
            print("    %s" % line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
