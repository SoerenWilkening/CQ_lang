#!/usr/bin/env python3
"""r1B (fmt3): cross the loop twin matrix's `rifelse` region (now a C-reachable ACCEPT)
with the axes the matrix gives `req`/`rder` but not `rifelse` (it sits in the E
'decline controls' group). Uses the matrix's OWN source generator and verdict()."""
import sys, os, types, concurrent.futures, argparse
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b"
sys.path.insert(0, W + "/tools")
import loop_twin_matrix as M
def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--include", default=W + "/include")
    ap.add_argument("--region", default="rifelse"); ap.add_argument("--jobs", type=int, default=3)
    a = ap.parse_args()
    cfg = types.SimpleNamespace(clang="/usr/local/opt/llvm@19/bin/clang", opt=W + "/build/ir-pass/cq-opt",
        plugin=W + "/build/ir-pass/libCQPass.so", include=a.include,
        runtime=W + "/build/runtime/libcq_runtime.a", templates=W + "/build/runtime/libcq_templates.a",
        ld=W + "/build/tests/e2e/cq_link.sh", phi_surface="void")
    g = a.region
    cells = [(p, g, s, "none", "none") for p, s in M.RY_A_STAR]
    cells += [("none", g, "none", "none", rg) for rg in M.RGATE if rg != "none"]
    cells += [("none", g, s, k, rg) for s in M.RY_C_SUFFIX for k in M.RECORD_R for rg in ("none", "rypost")]
    cells += [("none", g, "none", k, "none") for k in M.RECORD if k != "none"]
    with concurrent.futures.ProcessPoolExecutor(max_workers=a.jobs) as ex:
        for name, rolled, unrolled in ex.map(M._run_cell_star, [(cfg, c) for c in cells]):
            v, rep = M.verdict(name, rolled, unrolled)
            print("%-40s %s%s" % (name, v, ("  !! " + rep.splitlines()[0]) if rep else ""), flush=True)

if __name__ == '__main__':
    main()
