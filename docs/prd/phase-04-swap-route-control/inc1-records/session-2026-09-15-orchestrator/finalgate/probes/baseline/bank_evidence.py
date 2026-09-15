#!/usr/bin/env python3
"""bank_evidence.py — the EVIDENCE behind the 15 written reasons (Rule 12).

The gate (`finalgate/GATE.md` §4) measured WHICH cells moved. This driver
measures WHY: for every one of the 21 bank cells it runs BOTH sides on BOTH
binaries and prints the exit code, the first `cq ...` diagnostic, the trace and
`counts()` — so a reason can cite a measured stream rather than an inference
from the verdict string.

It imports `loop_twin_matrix` and calls its OWN `run_cell` / `verdict` /
`counts` (Rule 14); nothing here re-spells a comparison the gate owns.

    python3 bank_evidence.py --clang .. --include .. --runtime .. --templates ..
                             --subject-opt .. --subject-plugin ..
                             --oracle-opt ..  --oracle-plugin ..
                             [--only NAME,NAME] [--jobs 4] [--dump-src DIR]

Exits non-zero if it produced no rows (the `checked 0` hole, L10).
"""

import argparse
import concurrent.futures
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.abspath(os.path.join(HERE, *([".."] * 8), "tools"))
sys.path.insert(0, TOOLS)
import loop_twin_matrix as M  # noqa: E402


class Cfg:
    pass


def mk(base, opt, plugin):
    c = Cfg()
    for k, v in vars(base).items():
        setattr(c, k, v)
    c.opt, c.plugin = opt, plugin
    return c


def show(label, name, side):
    print("  %-8s %-8s exit=%s warns=%d" % (label, name, side.exit, side.warns))
    if side.error:
        print("      HARNESS-ERROR: %s" % side.error.splitlines()[0])
    if side.diag:
        print("      diag: %s" % side.diag)
    if side.trace:
        print("      counts(_unc, free, mints)=%s  lines=%d  measures=%d"
              % (M.counts(side.trace), len(side.trace.splitlines()),
                 side.trace.count("cqrt_measure_")))
        for ln in side.trace.splitlines():
            print("        | %s" % ln)


def main():
    ap = argparse.ArgumentParser()
    for f in ("clang", "include", "runtime", "templates",
              "subject-opt", "subject-plugin", "oracle-opt", "oracle-plugin"):
        ap.add_argument("--" + f, required=True, dest=f.replace("-", "_"))
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--ld", default=os.environ.get("CQ_LD", ""))
    ap.add_argument("--phi-surface", default="void")
    ap.add_argument("--only", default="")
    ap.add_argument("--dump-src", default="")
    cfg = ap.parse_args()

    cells = M.bank_cells()
    if cfg.only:
        keep = set(cfg.only.split(","))
        cells = [c for c in cells if M.cell_name(c) in keep]
    if not cells:
        print("REFUSED: no cells selected.")
        return 2

    if cfg.dump_src:
        os.makedirs(cfg.dump_src, exist_ok=True)
        for c in cells:
            n = M.cell_name(c)
            r, u = M.sources(*c, surface=cfg.phi_surface)
            open(os.path.join(cfg.dump_src, n + ".rolled.c"), "w").write(r)
            open(os.path.join(cfg.dump_src, n + ".unrolled.c"), "w").write(u)

    sub = mk(cfg, cfg.subject_opt, cfg.subject_plugin)
    ora = mk(cfg, cfg.oracle_opt, cfg.oracle_plugin)

    rows = {}
    for label, c in (("SUBJECT", sub), ("ORACLE", ora)):
        with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
            for name, rolled, unrolled in ex.map(
                    M._run_cell_star, [(c, x) for x in cells]):
                rows.setdefault(name, {})[label] = (rolled, unrolled)

    n = 0
    for name in sorted(rows):
        print("=" * 78)
        print(name)
        for label in ("ORACLE", "SUBJECT"):
            rolled, unrolled = rows[name][label]
            v, rep = M.verdict(name, rolled, unrolled)
            print("  %-8s VERDICT: %s" % (label, v))
            if rep:
                print("      HARD: %s" % rep.splitlines()[0])
            show(label, "rolled", rolled)
            show(label, "unrolled", unrolled)
        n += 1
    print("\n%d cell(s) measured on both binaries" % n)
    return 0 if n else 2


if __name__ == "__main__":
    sys.exit(main())
