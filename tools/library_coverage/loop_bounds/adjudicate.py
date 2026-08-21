#!/usr/bin/env python3
# adjudicate.py — bd 19v3: turn sweep_cells.py's raw SCEV inventory into the
# four-bucket population, applying the FIVE-condition test rather than
# `isa<SCEVConstant>`.
#
# THE INSTRUMENT MEASURES; THIS ADJUDICATES. Keeping the two apart is deliberate:
# LoopBoundProbe.cpp's `VERDICT bound-kind = CONSTANT` line is NOT a soundness
# test (it fires on fmod.f64's vacuous -2 = 4294967294 bound), and 8zj2 found two
# over-accept defects in exactly that gap. Every condition below is applied here,
# in the open, where it can be read.
#
# The five conditions (SPIKE-8zj2 §1a/§2/§2b):
#   C1 constant            constant-max BTC is a literal SCEVConstant
#   C2 non-negative        ... and is not a negative (i.e. vacuous wrapped) value
#   C3 small               ... and the +1 trip bound is realizable, not 4 billion
#   C4 reachability-total  the bound holds on EVERY basis state, not merely the
#                          guard-admitted ones (PredMux removes every guard)
#   C5 1 <= shift <= W-1   the shift-compare mechanism is P3-free only in range
#
# C1-C3 and C5 are mechanical and are decided here. C4 is NOT mechanical — it is
# the (A)-vs-(B) discriminator and needs per-loop evidence (entered
# unconditionally / opaque-provenance survival / exhaustive enumeration). This
# script marks every C1-C3+C5 survivor `NEEDS-C4` and never promotes one to
# bucket (A) on its own authority.
import json, re, sys, os
from pathlib import Path
from collections import Counter, defaultdict

OUT = Path(os.environ.get("CQ_SWEEP_OUT", "/private/tmp/cq19v3"))
# "Small" is a REALIZABILITY judgement, not a fact — reported, never hidden. 64
# is a bit-width-scale ceiling (the largest idiom width CQ lowers); the raw bound
# is printed for every loop so a different line can be drawn without re-running.
SMALL = int(os.environ.get("CQ_SMALL_MAX", "64"))
PRIMARY = "spec/passstyle"      # the module the pass sees, the SE the pass builds


def cmax_value(loop):
    """The constant-max BTC as an integer, or None if it is not a literal.
    Reads the reporter's printed SCEV, which for a SCEVConstant is the bare
    signed decimal (e.g. `32`, `-2`)."""
    s = (loop.get("btc_cmax") or "").strip()
    if not s or "COULDNOTCOMPUTE" in s:
        return None
    m = re.fullmatch(r'-?\d+', s)
    return int(m.group(0)) if m else None


def shift_amounts(mod_text):
    """Every constant shl/lshr/ashr amount in the WHOLE MODULE, with the shifted
    type's width. Returns [(op, amt, width)].

    *** MODULE-WIDE, NOT LOOP-SCOPED — say so wherever this is quoted. *** C5 asks
    about the shift inside the loop under test; this screens every shift in the
    cell. That is over-STRICT (the safe direction: it can only reject a loop for a
    shift belonging to some other loop, never accept one for an out-of-range shift
    of its own), and it is cheap because the reporter prints the header and latch
    but not the loop's full block list. On this population it passed for all 76
    loops — i.e. NO shl/lshr/ashr anywhere in any of the 19 loop-bearing cells has
    a constant amount outside [1, W-1] — so C5 never bound any classification here
    and the imprecision costs nothing. A recognizer must still do this properly,
    on the loop's own shift: bd 8zj2 measured that SCEV reports the type width even
    for a shift amount >= the width, although such a shift is poison and the loop
    is in fact infinite."""
    out = []
    for m in re.finditer(r'=\s+(shl|lshr|ashr)\b[^\n]*?\bi(\d+)\s+%?[^\n,]+,\s+(-?\d+)', mod_text):
        out.append((m.group(1), int(m.group(3)), int(m.group(2))))
    return out


def adjudicate_loop(loop, mod_text):
    v = cmax_value(loop)
    trip = loop.get("trip_max", 0)
    r = {"header": loop.get("header"), "dbg": loop.get("dbg"),
         "cmax": loop.get("btc_cmax"), "cmax_int": v, "trip_max": trip,
         "trip_exact": loop.get("trip_exact"), "n_exiting": loop.get("n_exiting"),
         "n_exits": loop.get("n_exits")}
    r["C1_constant"] = v is not None
    r["C2_nonneg"] = (v is not None and v >= 0)
    r["C3_small"] = (0 < trip <= SMALL)
    shifts = shift_amounts(mod_text) if mod_text else []
    r["shifts_module_wide"] = sorted(set(shifts))
    bad = [s for s in shifts if not (1 <= s[1] <= s[2] - 1)]
    r["C5_shift_in_range_MODULE_WIDE"] = (not bad)
    r["C5_offending"] = sorted(set(bad))
    if not r["C1_constant"]:
        r["verdict"] = "C-or-D: no SCEV bound (CouldNotCompute)"
    elif not (r["C2_nonneg"] and r["C3_small"]):
        r["verdict"] = "VACUOUS: constant but not usable"
    elif not r["C5_shift_in_range_MODULE_WIDE"]:
        r["verdict"] = "VACUOUS: out-of-range shift (poison-grounded bound)"
    else:
        r["verdict"] = "NEEDS-C4: bound usable IF total over every basis state"
    return r


def main():
    sweep = json.loads((OUT / "sweep.json").read_text())
    census = json.loads(Path(sys.argv[1]).read_text()) if len(sys.argv) > 1 else {}

    rows = {}
    disagree = []
    for cell, rec in sorted(sweep.items()):
        loops_by_view = rec.get("loops", {})
        prim = loops_by_view.get(PRIMARY)
        if prim in (None, "TIMEOUT"):
            prim = loops_by_view.get("inl/passstyle") or []
        # Cross-view disagreement is a RESULT (trap 4 / the pass-style SE risk),
        # not an internal detail — collect it rather than picking a winner.
        sig = {}
        for view, L in loops_by_view.items():
            if L == "TIMEOUT":
                sig[view] = "TIMEOUT"; continue
            sig[view] = sorted((l.get("dbg"), l.get("btc_cmax"), l.get("trip_max")) for l in L)
        vals = {json.dumps(v, sort_keys=True, default=str) for v in sig.values()}
        if len(vals) > 1:
            disagree.append((cell, sig))

        mod = (OUT / "cells" / cell / "spec.ll")
        mod_text = mod.read_text() if mod.exists() else ""
        rows[cell] = {
            "status": rec.get("status"), "bucket": rec.get("bucket"),
            "diag": rec.get("diag_full", ""), "provider": rec.get("provider"),
            "n_loops": len(prim),
            "loops": [adjudicate_loop(l, mod_text) for l in prim],
            "views": sorted(loops_by_view),
        }

    (OUT / "adjudicated.json").write_text(json.dumps(
        {"rows": rows, "cross_view_disagreements": disagree,
         "SMALL_MAX": SMALL, "primary_view": PRIMARY}, indent=1, default=str))

    # ---- report -----------------------------------------------------------
    print(f"cells swept: {len(rows)}   (primary view: {PRIMARY}, SMALL<= {SMALL})")
    print(f"cross-view disagreements: {len(disagree)}"
          + ("" if not disagree else "  <-- " + ", ".join(c for c, _ in disagree)))
    with_loops = {c: r for c, r in rows.items() if r["n_loops"]}
    print(f"cells with >=1 loop at the pass's observation point: {len(with_loops)}")
    print(f"  total loops: {sum(r['n_loops'] for r in with_loops.values())}")
    print()
    print("STATUS x HAS-LOOP")
    tally = Counter((r["status"].split(":")[0], bool(r["n_loops"])) for r in rows.values())
    for k, v in sorted(tally.items()):
        print(f"   {k[0]:14s} loops={k[1]!s:5s}  {v}")
    print()
    print("=== cells whose FIRST BLOCKER is a loop diagnostic ===")
    for c, r in sorted(rows.items()):
        if r["status"] != "decline":
            continue
        if "loop" not in r["diag"].lower():
            continue
        print(f"\n{c}  [{r['bucket']}]  loops={r['n_loops']}")
        print(f"   diag: {r['diag'][:150]}")
        for l in r["loops"]:
            print(f"   - {l['dbg']:44s} cmax={str(l['cmax'])[:22]:24s} trip={l['trip_max']:<11} "
                  f"exiting={l['n_exiting']} C1={int(l['C1_constant'])} C2={int(l['C2_nonneg'])} "
                  f"C3={int(l['C3_small'])} C5={int(l['C5_shift_in_range_MODULE_WIDE'])}  {l['verdict']}")
    print()
    print("=== NEEDS-C4 candidates (C1+C2+C3+C5 pass; totality UNDECIDED here) ===")
    n = 0
    for c, r in sorted(rows.items()):
        cand = [l for l in r["loops"] if l["verdict"].startswith("NEEDS-C4")]
        if not cand:
            continue
        n += 1
        print(f"  {c:18s} {r['status'][:20]:22s} {len(cand)}/{r['n_loops']} loops  "
              f"{[l['trip_max'] for l in cand]}")
    print(f"  ({n} cells)")


if __name__ == "__main__":
    main()
