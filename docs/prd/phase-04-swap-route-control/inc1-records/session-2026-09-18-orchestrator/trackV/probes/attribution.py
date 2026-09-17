#!/usr/bin/env python3
"""attribution.py — IS THE DIVERGENCE ABOUT THE NESTING?

Eight `l2*` cells diverge on the ORACLE. Before any of them is quarantined under
a bd id, the question a quarantine entry's `reason` has to answer is which half
of the program produces the divergence — and the only honest way to answer it is
to build the SAME program with one half removed and measure. That is what the
boundary control `q_nestinline` does for the interfered column; these are the
same isolation for the columns the control does not cover, run once, by hand,
and recorded rather than reasoned about.

Each row is a body built through `_wrap` exactly as a cell is, so nothing here is
a differently-shaped program than the cells it is attributing.

    python3 attribution.py <BUILD> <REPO>
"""
import os
import sys

# label -> (body, postloop)
BODIES = {
    # The s82e shape ITSELF, single loop, no inner anything: the outer bit rail
    # alone. If this diverges, class N-A is NOT about the nesting.
    "single_bitrail":
        ("        s += cq_measure((a >> (i + 1)) & 1);\n", ""),
    "single_bitrail_interfered":
        ("        s += cq_measure((a >> (i + 1)) & 1);\n",
         "    a = cq_theta(a, 0.9);\n"),
    # The n1 body with the inner loop INLINED and NO interference — the
    # `q_nestinline` control minus its post-loop line, which is the column the
    # control cannot speak for.
    "inline_noninterfered":
        ("        s += cq_measure((a >> (i + 1)) & 1);\n"
         "        { int u = cq_theta(6, 0.4); s += cq_measure((u >> 0) & 1); }\n"
         "        { int u = cq_theta(6, 0.4); s += cq_measure((u >> 1) & 1); }\n",
         ""),
    # The (ii-c) invariant read, inlined: `cq_measure(a & 1)` with no inner loop.
    # If this does NOT diverge, class N-B needs the inner loop — i.e. it needs
    # TWO loops for the rolled side to hoist one level further out than the flat.
    "inline_iic":
        ("        { int u = cq_theta(6, 0.4);"
         " s += cq_measure((u >> 0) & 1) + cq_measure(a & 1); }\n"
         "        { int u = cq_theta(6, 0.4);"
         " s += cq_measure((u >> 1) & 1) + cq_measure(a & 1); }\n", ""),
    # The same (ii-c) read with the inner loop ROLLED but NO outer loop, i.e.
    # ONE loop — the other half of the same isolation.
    #
    # ⚠ THE BRACES ARE REQUIRED AND THEIR ABSENCE WAS A MEASURED HARNESS ERROR,
    # recorded rather than quietly fixed: `second="acc"` has `scope` False, so
    # `_wrap` dedents the body and repeats it in ONE scope, and a bare
    # `int u = …` at body level is then a REDECLARATION that `clang` rejects —
    # the unrolled side built nothing and the row read `HARNESS-ERROR`. It is
    # the same artifact the RECORD axis designs around by hoisting `mark` out of
    # the loop, and the same one the cells avoid because their `int u` sits
    # inside the INNER LOOP's own braces.
    "single_iic_loop":
        ("        { int u = cq_theta(6, 0.4);"
         " s += cq_measure((u >> i) & 1) + cq_measure(a & 1); }\n", ""),
}


def main():
    build, repo = sys.argv[1], sys.argv[2]
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

    import shutil
    import tempfile
    for label, (body, post) in BODIES.items():
        r_src, u_src = M._wrap(body, "acc", M.RECORD["none"], "void",
                               index=True, postloop=post)
        work = tempfile.mkdtemp(prefix="cqattr_")
        try:
            r = M.build_side(Cfg, work, label, r_src)
            u = M.build_side(Cfg, work, label + "_u", u_src)
        finally:
            shutil.rmtree(work, ignore_errors=True)
        v, _ = M.verdict(label, r, u)
        print("%-28s %s" % (label, v.split("\t")[0]))
        print("    counts rolled %s over %d lines / unrolled %s over %d lines"
              % (M.counts(r.trace), len(r.trace.splitlines()),
                 M.counts(u.trace), len(u.trace.splitlines())))
        if v.startswith("TRACE-DIVERGENCE"):
            d, rl, ul = M.divergence_signature(r.trace, u.trace)
            print("    digest %s | rolled %s | unrolled %s" % (d, rl, ul))
            for line in difflib.unified_diff(r.trace.splitlines(),
                                             u.trace.splitlines(),
                                             fromfile="rolled",
                                             tofile="unrolled",
                                             lineterm="", n=1):
                print("        %s" % line)
        elif v.split("\t")[0].startswith("DECLINE") or "ONLY" in v:
            print("    %s" % v.replace("\t", " | "))
    return 0


if __name__ == "__main__":
    sys.exit(main())
