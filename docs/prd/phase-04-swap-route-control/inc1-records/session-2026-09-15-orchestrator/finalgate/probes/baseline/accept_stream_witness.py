#!/usr/bin/env python3
"""accept_stream_witness.py — the CROSS-BINARY / CROSS-CELL check behind the
five accepting BANK rolled sides (bd rpkr axis, Rule-12 regeneration).

`ACCEPT-IDENTICAL` cannot see a defect BOTH halves share (CLAUDE.md L10,
`m_none_pbitd_none_premark_rypost`), and the three `ROLLED-ONLY` cells have no
accepting twin at all (finalgate F-3). So this driver asks two questions the
matrix does not:

  Q1  Is the SUBJECT's ROLLED bank stream byte-identical to the stream the
      ORACLE — a compiler with no rail bank in it — already emitted for the
      SROA-scalarised twin?  That is witness W-B stated against an INDEPENDENT
      compiler rather than against the subject's own other half.

  Q2  For a `kloop` cell whose twin declines, is the rolled stream the same
      GATE stream as its `kflat` sibling's (which Q1 pins), with only the
      `cqrt_measure_` lines permuted exactly as the two sources permute them?

Neither is a gate and neither is the unitary (Rule 2). Q1 is a real oracle
comparison; Q2 is a cross-cell consistency measurement and is labelled as one.

Exits non-zero if it checked nothing.
"""

import argparse
import concurrent.futures
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.abspath(os.path.join(HERE, *([".."] * 8), "tools"))
sys.path.insert(0, TOOLS)
import loop_twin_matrix as M  # noqa: E402

PAIRS = [("m_none_kprep_none_none_kflat", "m_none_kprep_none_none_kloop"),
         ("m_none_k2b_none_none_kflat",   "m_none_k2b_none_none_kloop")]
# `kiprep` has no accepting `kflat` sibling (that cell declines at the carve's
# mixed-access clause), so its Q2 reference is the `_Bool` design target at the
# same read shape, compared MODULO the cell width token.
WIDTH_PAIR = ("m_none_kprep_none_none_kloop", "m_none_kiprep_none_none_kloop")


class Cfg:
    pass


def mk(base, opt, plugin):
    c = Cfg()
    for k, v in vars(base).items():
        setattr(c, k, v)
    c.opt, c.plugin = opt, plugin
    return c


def gates(trace):
    return [l for l in trace.splitlines() if "cqrt_measure_" not in l]


def measures(trace):
    return [l for l in trace.splitlines() if "cqrt_measure_" in l]


def main():
    ap = argparse.ArgumentParser()
    for f in ("clang", "include", "runtime", "templates",
              "subject-opt", "subject-plugin", "oracle-opt", "oracle-plugin"):
        ap.add_argument("--" + f, required=True, dest=f.replace("-", "_"))
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--ld", default=os.environ.get("CQ_LD", ""))
    ap.add_argument("--phi-surface", default="void")
    cfg = ap.parse_args()

    want = set()
    for a, b in PAIRS:
        want |= {a, b}
    want |= set(WIDTH_PAIR)
    cells = [c for c in M.bank_cells() if M.cell_name(c) in want]
    if not cells:
        print("REFUSED: no cells selected.")
        return 2

    res = {}
    for label, c in (("SUBJECT", mk(cfg, cfg.subject_opt, cfg.subject_plugin)),
                     ("ORACLE", mk(cfg, cfg.oracle_opt, cfg.oracle_plugin))):
        with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
            for name, rolled, unrolled in ex.map(
                    M._run_cell_star, [(c, x) for x in cells]):
                res.setdefault(name, {})[label] = (rolled, unrolled)

    checked = 0
    bad = 0

    print("Q1 — SUBJECT rolled bank  ==  ORACLE unrolled scalar cascade")
    for flat, _ in PAIRS:
        sr = res[flat]["SUBJECT"][0].trace
        ou = res[flat]["ORACLE"][1].trace
        su = res[flat]["SUBJECT"][1].trace
        ok = bool(sr) and sr == ou and sr == su
        print("  %-34s rolled(SUB)==unrolled(ORA): %-5s  "
              "rolled(SUB)==unrolled(SUB): %-5s  lines=%d"
              % (flat, sr == ou, sr == su, len(sr.splitlines())))
        checked += 1
        bad += 0 if ok else 1

    print("Q2 — ROLLED-ONLY `kloop` rolled stream vs its `kflat` sibling")
    for flat, loop in PAIRS:
        f = res[flat]["SUBJECT"][0].trace
        l = res[loop]["SUBJECT"][0].trace
        # ⚠ NON-VACUITY FIRST. `gates("") == gates("")` is True, so a pair of
        # EMPTY traces (both sides declined) would score every comparison below
        # as a pass — the L10 failure mode, and my own self-attack produced it
        # before this guard existed. Both traces must be non-empty and must
        # carry the floor's measurements before any equality is believed.
        live = bool(f) and bool(l) and bool(measures(f)) and bool(measures(l))
        g = live and gates(f) == gates(l)
        m = live and sorted(measures(f)) == sorted(measures(l))
        o = live and measures(f) != measures(l)
        print("  %-34s non-vacuous: %-5s  gate-stream identical: %-5s  "
              "measure multiset equal: %-5s  measure ORDER differs (as the "
              "sources do): %s" % (loop, live, g, m, o))
        checked += 1
        bad += 0 if (live and g and m) else 1

    print("Q2b — `kiprep` (int cells) vs `kprep` (_Bool cells), modulo width")
    b, i = (res[WIDTH_PAIR[0]]["SUBJECT"][0].trace,
            res[WIDTH_PAIR[1]]["SUBJECT"][0].trace)
    # The ONLY licensed difference is the cell rails' width token. `a` is `int`
    # in both, so a blind i1->i32 rewrite of the _Bool side must reproduce the
    # int side exactly.
    live = bool(b) and bool(i)          # same non-vacuity guard as Q2
    norm = b.replace("_i1(", "_i32(")
    print("  %-34s non-vacuous: %-5s  i1->i32 rewrite of _Bool stream == int "
          "stream: %s  (lines %d / %d)"
          % (WIDTH_PAIR[1], live, live and norm == i,
             len(b.splitlines()), len(i.splitlines())))
    checked += 1
    bad += 0 if (live and norm == i) else 1

    print("\nchecked %d comparison(s), %d unexpected" % (checked, bad))
    if not checked:
        return 2
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
