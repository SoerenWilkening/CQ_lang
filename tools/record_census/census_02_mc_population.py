#!/usr/bin/env python3
"""census_02_mc_population.py — Inc-0 census 0.2: the M-C in-place-reassignment
population, and the e2e goldens an M-C increment would have to regenerate.

M-C is the Grover fix in the record-family plan of record (bd
test_C_libtooling-6uqc): widen `ArithLowering::rewriteInPlaceValueRail`
(ir-pass/src/ArithLowering.cpp:189 — today reachable only through the dtzb
loop path, `taint.InPlaceRailOps`) so a single-consumer tainted
add/sub/xor-by-a-classical lowers to the ALREADY-FROZEN in-place
`cqrt_addc_<W>` / `cqrt_xorc_<W>` instead of the out-of-place
`cq_template_<op>_<W>_hl`, which keeps its source rail alive as a basis record
(bd test_C_libtooling-nepx). No new frozen symbol; `EmitInverse` already
adjoints both.

Two things this file settles:
  * Risk 2 of the plan — the Inc-2 reviewer needs an ACCEPT TABLE, so every
    eligible site is emitted with the parent handle's COMPLETE later-user list.
  * Amendment (2) of the session review — "if Inc0.2 shows >~20 goldens change
    under M-C, split the regeneration into its own reviewed commit".

================================ THE FENCE =================================
A call site qualifies iff ALL of:

  F1  callee is `cq_template_<op>_<W>_hl` or `cq_template_<op>_<W>_lh`
      with op in {add, sub, xor};
  F2  W is a width the in-place runtime grid COVERS. Read from
      `runtime/cq_runtime.h` and pinned here as {i1, i8, i16, i32, i64} —
      `cqrt_addc_*`/`cqrt_xorc_*` exist at exactly those five widths and at NO
      floating width (the plan's owner-decision (c): fp reassignment stays a
      decline, freeze untouched). The script CHECKS the header at run time and
      fails loudly if the grid has moved, rather than trusting this comment.
  F3  DIRECTION. `_hl` (handle, literal) qualifies for all three ops. `_lh`
      (literal, handle) qualifies for `add` and `xor` only: `c - q` is not an
      in-place add of a classical into `q`, so a `sub_<W>_lh` is NOT eligible.
  F4  the PARENT handle (`_hl` arg 0 / `_lh` arg 1) has NO later use in the
      function other than an in-place void rotation on that same handle
      (`cqrt_ry_<W>(P, …)` / `cqrt_rz_<W>(P, …)`). ANY other later use — another
      template call, `cqrt_measure`, `cqrt_cswap`, an `_unc` that READS it, a
      copy/tape sink, or a plain-IR use such as `ret`/`store`/`phi` —
      disqualifies.

"Later" is by source-text line within the function (census_common APPROXIMATION
1). Uses are found by a RAW-TEXT token scan over the function's own line range,
not by the call parser alone, precisely so that `ret i32 %P` and `store i32 %P`
cannot slip through a call-only model.

============================= WHAT ELSE IT PRINTS ==========================
The fence above is the plan's, and applying it as written produces a striking
result that the census reports rather than smooths over: the `_unc` twin of the
very call under test READS the parent handle
(`cq_template_add_i32_hl_unc(%out, %P, 3)`), so ANY site whose own result is
later uncomputed by the Phase-5 spine fails F4. FOUR RELAXATIONS are therefore
measured beside the strict count, each as its own column, so the Inc-2 author
prices the fence rather than discovering it:

  R1  SELF-UNC — ignore an `_unc` whose base is this call's own symbol and whose
      operands match this call's (i.e. this call's adjoint). Physically an
      in-place lowering replaces the forward AND its adjoint together, so this
      use is not evidence that the parent must survive.
  R2  WIDER IN-PLACE — also allow `cqrt_addc`/`cqrt_xorc`/`cqrt_x` on the parent
      (all void in-place gates that mint no value), not only `ry`/`rz`.
  R3  FREE — `cqrt_free(%P)` counted separately: an in-place lowering deletes the
      parent rail entirely, so a later free of it must be removed too. This is
      reported, never silently allowed.
  R4  SPINE-OWNED PARENT — also allow an `_unc` whose OUT slot is the parent
      (the whole-DAG spine discharging the parent rail) plus its `cqrt_free`.
      This is the largest single dial: it is the population whose eligibility
      turns on Inc 2 rewriting the UNCOMPUTE PLAN, not just the forward gate.

And, in the opposite (tightening) direction, one column that is NOT a relaxation:

  SC  SINGLE-CONSUMER. The plan of record (bd nepx) words M-C as
      "single-consumer tainted-op-classical add/sub/xor"; the fence handed to
      this census words F4 as "the ONLY consumers AFTER this call". Those are
      different predicates, and the difference is 307 vs 233 sites (84 vs 68
      goldens), so it is measured rather than resolved by fiat. The SC column
      additionally requires that the parent have NO earlier out-of-place
      consumer. It matters: if an earlier consumer's ADJOINT is ever emitted
      after this site, an in-place mutation of the parent makes that adjoint
      recompute from a moved source — the (T2) failure
      `free_pairing_check.py` exists to catch. Every SC-failing site measured
      here happens to have no such adjoint in the corpus TODAY, so the strict
      column is not currently unsound; it is merely resting on an accident.

============================ APPROXIMATION DIRECTIONS ======================
  A1  Textual order (as above). `multi_block_fns` is reported.
  A2  No interprocedural analysis: a parent handle passed to a call this model
      does not know is treated as a disqualifying use. Direction: UNDER-counts
      eligible sites (safe for a population estimate, and stated).
  A3  The census reads LOWERED IR, but M-C is a decision made on PRE-lowering IR
      (`rewriteInPlaceValueRail` runs inside `lowerOps`). The lowered
      `cq_template_<op>_<W>_hl` call IS the 1:1 image of the pre-lowering binop,
      and lowering does not reorder it, so the site set is exact; what the
      lowered view cannot see is a binop that DECLINED before `lowerOps` (those
      modules produce no lowered IR at all — see census 0.4's note).
  A4  A "golden would change" verdict is STRUCTURAL: a slice with >=1 eligible
      site emits at least one different gate. It does not predict how many lines
      of the golden move.

================================== RE-RUN ==================================
    python3 tools/record_census/census_02_mc_population.py \
        --json docs/prd/record-family/census-0.2-mc-population.json
"""

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402

fpc = cc.fpc

MC_OPS = ("add", "sub", "xor")
SITE_RE = re.compile(rf"^cq_template_({'|'.join(MC_OPS)})_({fpc._W})_(hl|lh)$")
INPLACE_ROT_RE = re.compile(rf"^cqrt_(ry|rz)_{fpc._W}$")
WIDER_INPLACE_RE = re.compile(rf"^(cqrt_(addc|xorc)_{fpc._W}|cqrt_x)$")


def inplace_grid(repo=cc.REPO):
    """The widths `cqrt_addc_<W>`/`cqrt_xorc_<W>` actually exist at.

    MEASURED from runtime/cq_runtime.h, not asserted: F2 is a claim about the
    frozen ABI, and a hand-written width list is exactly how a census comes to
    measure a program that does not exist.
    """
    hdr = os.path.join(repo, "runtime", "cq_runtime.h")
    text = open(hdr, errors="replace").read()
    addc = set(re.findall(r"\bcqrt_addc_(\w+)\s*\(", text))
    xorc = set(re.findall(r"\bcqrt_xorc_(\w+)\s*\(", text))
    if not addc or addc != xorc:
        raise SystemExit(f"census 0.2: addc/xorc grids disagree in {hdr}: "
                         f"addc={sorted(addc)} xorc={sorted(xorc)}")
    return addc


def name_uses(lf, name, after_line):
    """[(lineno, text)] — every raw line of `lf` after `after_line` mentioning
    the SSA value `name` as a whole token."""
    pat = re.compile(re.escape(name) + r"(?![\w.$])")
    return [(n, t) for n, t in lf.raw_lines()
            if n > after_line and pat.search(t)]


def classify_use(lf, call_by_line, lineno, text, parent, site):
    """-> (kind, detail). kind is one of:
         'inplace-rot'  cqrt_ry/rz on the parent (ALLOWED by F4)
         'inplace-wide' cqrt_addc/xorc/x on the parent (R2 only)
         'self-unc'     this site's own adjoint reading the parent (R1 only)
         'unc-out'      an `_unc` whose OUT slot IS the parent — the whole-DAG
                        spine DISCHARGING the parent rail, not reading it (R4)
         'free'         cqrt_free(parent) (R3/R4, reported)
         'measure'      cqrt_measure_<W>(parent) (DISQUALIFIES)
         'call'         any other call using the parent (DISQUALIFIES)
         'ir'           a non-call IR use: ret/store/phi/... (DISQUALIFIES)
    """
    c = call_by_line.get(lineno)
    if c is None:
        return "ir", text.strip()
    if parent not in c.vals:
        # the parent appears on a call line only as part of the RESULT name or a
        # type — the token scan is deliberately loose, the call parser is exact.
        return "none", text.strip()
    if c.sym == "cqrt_free":
        return "free", text.strip()
    if INPLACE_ROT_RE.match(c.sym) and c.vals and c.vals[0] == parent:
        return "inplace-rot", text.strip()
    if WIDER_INPLACE_RE.match(c.sym) and c.vals and c.vals[0] == parent:
        return "inplace-wide", text.strip()
    if c.sym == site.sym + "_unc" and len(c.vals) == len(site.vals) + 1 \
            and c.vals[1:] == site.vals and c.vals[0] == site.res:
        return "self-unc", text.strip()
    if c.sym.endswith("_unc") and c.vals and c.vals[0] == parent:
        return "unc-out", text.strip()
    if re.fullmatch(rf"cqrt_measure_{fpc._W}", c.sym):
        return "measure", text.strip()
    return "call", text.strip()


def analyse_module(path, label, grid):
    _, fns = cc.parse_lowered(path)
    sites, multi = [], 0
    for lf in fns:
        if lf.nblocks > 1:
            multi += 1
        by_line = {c.line: c for c in lf.calls}
        mint = {}
        for c in lf.calls:
            k = cc.mint_kind(c)
            if k and c.res:
                mint[c.res] = k
        for c in lf.calls:
            m = SITE_RE.match(c.sym)
            if not m:
                continue
            op, width, shape = m.group(1), m.group(2), m.group(3)
            rec = {"module": label, "fn": lf.name, "line": c.line,
                   "sym": c.sym, "op": op, "width": width, "shape": shape,
                   "result": c.res, "args": c.vals}
            if width not in grid:
                rec.update(verdict="decline-width", reason=f"no cqrt_addc_{width}")
                sites.append(rec)
                continue
            if op == "sub" and shape == "lh":
                rec.update(verdict="decline-direction",
                           reason="c - q is not an in-place add")
                sites.append(rec)
                continue
            if len(c.vals) != 2:
                rec.update(verdict="decline-arity",
                           reason=f"{len(c.vals)} args")
                sites.append(rec)
                continue
            parent = c.vals[0] if shape == "hl" else c.vals[1]
            rec["parent"] = parent
            rec["parent_kind"] = mint.get(parent, "param-or-unknown")
            uses = []
            for n, t in name_uses(lf, parent, c.line):
                kind, detail = classify_use(lf, by_line, n, t, parent, c)
                if kind == "none":
                    continue
                uses.append({"line": n, "kind": kind, "text": detail})
            rec["later_uses"] = uses
            # PRIOR uses of the parent. The plan of record (bd nepx) words M-C
            # as "single-consumer"; the fence handed to this census words it as
            # "ONLY consumers AFTER this call". Those are NOT the same predicate
            # and the difference is measured, never split by fiat: a parent with
            # an EARLIER out-of-place consumer is not single-consumer, and if
            # that consumer's adjoint is ever emitted after this site, the
            # in-place mutation makes the adjoint recompute from a moved source
            # (the exact (T2) failure `free_pairing_check` documents). Uses that
            # are themselves in-place gates on the parent are not consumers.
            #
            # "Consumer" is decided by `free_pairing_check.classify()`'s effect
            # model, not by textual mention: a call that WRITES the parent
            # (`cqrt_copy_<W>_controlled(ctl, src, %P)` — the 4.4 merge, whose
            # dst is the parent) is not a consumer of its value, and neither is
            # an in-place gate. A prior consumer is a call that READS the parent
            # AND mints a fresh rail from it, i.e. an out-of-place producer whose
            # adjoint would have to recompute from the parent's ORIGINAL value.
            prior = []
            for n, t in lf.raw_lines():
                if n >= c.line:
                    continue
                if not re.search(re.escape(parent) + r"(?![\w.$])", t):
                    continue
                pc = by_line.get(n)
                if pc is None:
                    prior.append({"line": n, "kind": "ir", "text": t.strip()})
                    continue
                if parent not in pc.vals:
                    continue          # a result name / type coincidence
                try:
                    eff = fpc.classify(pc.sym)
                except fpc.Unclassified:
                    eff = None
                if eff is None:
                    prior.append({"line": n, "kind": "unclassified",
                                  "text": t.strip()})
                    continue
                pc.eff = eff        # `read_idx()` resolves the ALL sentinels
                reads = {pc.vals[j] for j in pc.read_idx() if j < len(pc.vals)}
                if parent not in reads:
                    continue          # written, not consumed
                if eff.mints is None:
                    continue          # read as a control/source by a gate that
                                      # mints nothing — no adjoint recompute
                prior.append({"line": n, "kind": "out-of-place-consumer",
                              "text": t.strip()})
            rec["prior_consumers"] = prior
            kinds = [u["kind"] for u in uses]
            strict_bad = [k for k in kinds if k not in ("inplace-rot",)]
            r1_bad = [k for k in kinds if k not in ("inplace-rot", "self-unc")]
            r2_bad = [k for k in kinds
                      if k not in ("inplace-rot", "self-unc", "inplace-wide")]
            r4_bad = [k for k in kinds
                      if k not in ("inplace-rot", "self-unc", "inplace-wide",
                                   "unc-out", "free")]
            rec["eligible_strict"] = not strict_bad
            rec["eligible_r1_selfunc"] = not r1_bad
            rec["eligible_r2_wider"] = not r2_bad
            rec["eligible_r4_spine_owned"] = not r4_bad
            rec["eligible_single_consumer"] = (not strict_bad) and not prior
            rec["has_free"] = "free" in kinds
            rec["verdict"] = ("eligible" if not strict_bad else
                              "eligible-under-R1" if not r1_bad else
                              "eligible-under-R2" if not r2_bad else
                              "eligible-under-R4" if not r4_bad else
                              "decline-users")
            sites.append(rec)
    return sites, multi


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--repo", default=cc.REPO)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--dump", action="store_true",
                    help="print the full later-user list for every candidate")
    args = ap.parse_args(argv)

    grid = inplace_grid(args.repo)
    import concurrent.futures as cfut
    work = [("lit:" + n, p, None) for n, p, _ in cc.lit_fixtures(args.repo)]
    work += [("e2e:" + s["name"], None, s) for s in cc.e2e_slices(args.repo)
             if s["kind"] in ("single", "multi")]

    def go(item):
        label, path, sl = item
        if path is not None:
            rc, out, _ = cc.lower_ll(path, args.repo)
        else:
            rc, out, _ = cc.lower_slice(sl, args.repo)
        if rc != 0 or out is None:
            return None
        return analyse_module(out, label, grid)

    with cfut.ThreadPoolExecutor(max_workers=args.jobs) as ex:
        res = [r for r in ex.map(go, work) if r is not None]
    sites = [s for r, _ in res for s in r]
    multi = sum(m for _, m in res)

    cand = [s for s in sites if s["verdict"].startswith("eligible")
            or s["verdict"] == "decline-users"]
    elig = [s for s in cand if s.get("eligible_strict")]
    r1 = [s for s in cand if s.get("eligible_r1_selfunc")]
    r2 = [s for s in cand if s.get("eligible_r2_wider")]
    r4 = [s for s in cand if s.get("eligible_r4_spine_owned")]
    sc = [s for s in cand if s.get("eligible_single_consumer")]

    def goldens(pool):
        return sorted({s["module"] for s in pool if s["module"].startswith("e2e:")})

    report = {
        "inplace_grid": sorted(grid),
        "total_site_shaped_calls": len(sites),
        "candidates_after_F1_F3": len(cand),
        "declined_width": sorted({s["module"] for s in sites
                                  if s["verdict"] == "decline-width"}),
        "declined_direction": [s for s in sites
                               if s["verdict"] == "decline-direction"],
        "eligible_strict": len(elig),
        "eligible_r1_selfunc": len(r1),
        "eligible_r2_wider": len(r2),
        "eligible_r4_spine_owned": len(r4),
        "eligible_single_consumer": len(sc),
        "eligible_single_consumer_sites": sc,

        "eligible_strict_sites": elig,
        "eligible_r1_sites": r1,
        "goldens_changed_strict": goldens(elig),
        "goldens_changed_r1": goldens(r1),
        "goldens_changed_r2": goldens(r2),
        "goldens_changed_r4": goldens(r4),
        "goldens_changed_single_consumer": goldens(sc),
        "sites_with_later_free": len([s for s in cand if s.get("has_free")]),
        "multi_block_fns": multi,
        "all_candidates": cand,
    }

    print(f"in-place runtime grid (measured from cq_runtime.h): "
          f"{', '.join(sorted(grid))}")
    print(f"add/sub/xor _hl/_lh template calls in corpus : {len(sites)}")
    print(f"  after F2 width + F3 direction fences        : {len(cand)}")
    print(f"  declined on width  (fp / i128 / …)          : "
          f"{len([s for s in sites if s['verdict'] == 'decline-width'])}")
    print(f"  declined on direction (sub _lh)             : "
          f"{len([s for s in sites if s['verdict'] == 'decline-direction'])}")
    print()
    print(f"ELIGIBLE, fence exactly as written (F4 strict): {len(elig)} sites, "
          f"{len(goldens(elig))} e2e goldens")
    print(f"  + R1 (ignore this site's own `_unc`)        : {len(r1)} sites, "
          f"{len(goldens(r1))} e2e goldens")
    print(f"  + R2 (also allow addc/xorc/x on the parent) : {len(r2)} sites, "
          f"{len(goldens(r2))} e2e goldens")
    print(f"  + R4 (also allow the SPINE to own the parent:"
          f" its `_unc` + free)  : {len(r4)} sites, "
          f"{len(goldens(r4))} e2e goldens")
    print(f"SINGLE-CONSUMER reading (strict F4 AND no earlier out-of-place\n"
          f"  consumer of the parent — the plan's own wording)"
          f"           : {len(sc)} sites, {len(goldens(sc))} e2e goldens")
    print(f"  candidate sites with a later cqrt_free(P)   : "
          f"{report['sites_with_later_free']}")
    print(f"multi-block functions in corpus               : {multi}")
    print()
    print("ELIGIBLE SITES (strict) — parent-handle accept table:")
    for s in elig:
        print(f"  {s['module']} fn={s['fn']} line={s['line']} {s['sym']}"
              f"({', '.join(s['args'])}) -> {s['result']}")
        print(f"      parent {s['parent']} ({s['parent_kind']}); later uses: "
              f"{len(s['later_uses'])}")
        for u in s["later_uses"]:
            print(f"        [{u['kind']}] :{u['line']} {u['text']}")
    print()
    print("ELIGIBLE ONLY UNDER R1 (self-`_unc` ignored):")
    for s in r1:
        if s.get("eligible_strict"):
            continue
        print(f"  {s['module']} fn={s['fn']} line={s['line']} {s['sym']}"
              f"({', '.join(s['args'])}) -> {s['result']}")
        for u in s["later_uses"]:
            print(f"        [{u['kind']}] :{u['line']} {u['text']}")
    print()
    print(f"e2e goldens that would change, STRICT ({len(goldens(elig))}):")
    for g in goldens(elig):
        print("   ", g)
    print(f"e2e goldens that would change, R1 ({len(goldens(r1))}):")
    for g in goldens(r1):
        print("   ", g)
    print(f"e2e goldens that would change, R4 ({len(goldens(r4))}):")
    for g in goldens(r4):
        print("   ", g)
    if args.dump:
        print("\nALL CANDIDATES:")
        for s in cand:
            print(f"  {s['verdict']:20s} {s['module']} :{s['line']} {s['sym']} "
                  f"parent={s.get('parent')} "
                  f"uses={[u['kind'] for u in s.get('later_uses', [])]}")
    if args.json:
        with open(args.json, "w") as f:
            json.dump(report, f, indent=1, sort_keys=True)
        print(f"\nwrote {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
