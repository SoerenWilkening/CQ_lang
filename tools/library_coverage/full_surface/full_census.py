#!/usr/bin/env python3
# Full-surface injection census — the width/by-ref/int-ret widening of
# inject_census.py the roadmap intended. Imports probe.py's MATHH_SPEC as the
# authoritative surface, expands each base fn across its width variants (f/d/l),
# injects the REAL openlibm body per cell, runs cq-lowering, records the actual
# blocking capability. Skips the hardware keep-set (recognition-covered, no
# injectable body), macros, and by-design. Reuses wprobe.py's pipeline.
import sys, json, os
from pathlib import Path
from collections import defaultdict
# probe.py lives one dir up (tools/library_coverage); wprobe.py sits alongside.
sys.path.insert(0, str(Path(__file__).resolve().parent))          # wprobe
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # probe
import wprobe as WP
import probe as P

# variant key -> (census width, c-type, spelling suffix, fp-const literal)
VAR = {"f": ("f32","float","f","0.5f"), "": ("f64","double","","0.5"), "l": ("f80","long double","l","0.5L")}
KEEP = set(P.HARDWARE_KEEP_SET.split())   # recognition-covered; no injectable body

def cell_args(spec, width, ctype, lit):
    """Map a spec's arg kinds to wprobe arg descriptors (arg0 tainted)."""
    out = []
    for i, a in enumerate(spec["args"]):
        if a == "fp":
            out.append(("q", width) if i == 0 else (f"c:{ctype}:{lit}",))
        elif a == "int":   out.append(("c:int:2",))
        elif a == "long":  out.append(("c:long:2",))
        elif a == "ldbl":  out.append(("c:long double:0.5L",))   # nexttoward 2nd arg (always long double)
        elif a == "int*":  out.append(("ref:int",))
        elif a == "fp*":   out.append((f"ref:{ctype}",))
        elif a == "str":   return None   # nan("") — no taintable input
        else: return None
    return out

def ret_width(spec, width):
    r = spec["ret"]
    if r == "fp":   return width
    if r == "long": return "sl"
    return None   # int-return macros — skipped

def bucket(st, diag):
    d = diag.lower()
    if st == "COMPILES": return "COMPILES"
    if st.startswith("exit0-spec"): return "COMPILES (spec-clone)"
    if st.startswith("exit0"): return "uninlined(harness)"
    if "nested control" in d: return "L6 nested control"
    if "control flow inside a loop" in d: return "in-loop control"
    if "arm rewrites a condition" in d: return "§3c clobber"
    if "control flow under quantum" in d: return "control (flat/diamond)"
    if "unknown callee" in d: return "unknown callee (inner-call)"
    if "unsupported instruction" in d: return "unsupported opcode"
    if "stored to memory" in d or "store" in d: return "memory-store (Shadow)"
    if "reversible copy" in d or "specialization" in d: return "fp-copy/specialization"
    if "loop" in d: return "loop-carried"
    if "angle" in d: return "angle-fence"
    return "other: " + d[:50]

# ---------------------------------------------------------------------------
# SCOPE — the "is this work?" axis. ORTHOGONAL to `bucket`.
# ---------------------------------------------------------------------------
# `bucket` names the MECHANISM of the first blocker and deliberately says NOTHING
# about whether the cell is work we intend to do. That gap has misled planning
# twice, both times in the expensive direction:
#   * 2026-07-25 — "bounded loops are ~half of all declines (24/55), 8h7d is by
#     far the highest coverage-per-effort lever". INVERTED: 17 of the 24 were
#     harness artifacts or belonged to other levers.
#   * 2026-07-27 — "take the fmod/remainder/remquo 9 BEFORE Payne-Hanek, it rides
#     an existing lever". ANSWERED NO, at a measured payoff of ZERO cells.
# Both misreadings were possible because an owner-decided cell and an actionable
# one carry the SAME bucket label. `SCOPE` closes that.
#
#   decided-decline   The construct CQ would have to lower is owner-ruled out of
#                     scope (CLAUDE.md Rule 18 condition (2), owner decision
#                     2026-07-27). NOT a physics wall and NOT permanent — every
#                     entry names the ruling and what would re-open it. What it
#                     DOES mean: do not scope compiler work against this cell.
#   lever-gap         A real capability we could build that WOULD move this cell.
#                     *** THIS IS THE ACTIONABLE SET. ***
#   deferred-capability  Real, scoped elsewhere, and not this bucket's work.
#   corpus-gap        Not a compiler fact at all (no injectable body).
#   owner-ruling-needed  Measured, but falls on a line only the owner can draw.
#
# Second field = the evidence of record. A `decided-decline` with no citation is
# an assertion, and assertions are what this table exists to retire.
SCOPE = {
    # -- fmod/remainder/remquo x3 widths: doubly-grounded parity inversion.
    #    Bennett ships NO frem/fmod algorithm at ANY width (Leg A, re-verified
    #    at rev e15ea23 2026-07-28: the only rem|mod token in src/ is an error
    #    string), AND its data-dependent-loop mechanism is a K-parameterized
    #    unroller, not a concrete gate sequence (Leg B). Payoff of the best
    #    design measured at ZERO cells: 9/9 have a loop SCEV cannot bound at all.
    **{c: ("decided-decline", "SCOPING-L3-data-dependent-trip-loops.md (owner 2026-07-27); re-open only via its §6")
       for c in ("fmod.f64", "fmodf.f32", "fmodl.f80",
                 "remainder.f64", "remainderf.f32", "remainderl.f80",
                 "remquo.f64", "remquof.f32", "remquol.f80")},

    # -- sin/cos/tan x3 widths: Payne-Hanek. SINGLY grounded, and the difference
    #    from fmod is load-bearing (measured 2026-07-28): Bennett DOES back
    #    sin/cos/tan by a CONCRETE branchless fixed-window Payne-Hanek
    #    (src/softfloat/fsin.jl:468 _rp_paynehanek, zero for/while). What is
    #    ruled out is openlibm's SOURCE FORM — k_rem_pio2.c's nested
    #    data-dependent loops, which Bennett would reject too. CLAUDE.md Rule 18
    #    names "Payne-Hanek `rem_pio2`" verbatim. The parity-correct answer is
    #    the authored branchless leaf (bd 20xt.8), which by the campaign's own
    #    honesty rule leaves the CENSUS cell declined.
    #    The f32/f64 bucket split is a pure SROA artifact: e_rem_pio2f.c:47
    #    `double tx[1]` promotes to SSA while e_rem_pio2.c:55 `double tx[3]`
    #    survives, so the f32 trio blocks one call DEEPER (inside k_rem_pio2)
    #    on the @ipio2 QROM read instead of on the tx fill store. Same capability.
    #    *** READ THE scope_ref, NOT THE CELL NAME. *** "sin.f64: decided-decline"
    #    does NOT mean CQ cannot do quantum sin. It means openlibm's s_sin.c +
    #    e_rem_pio2.c + k_rem_pio2.c cannot be lowered AS INJECTED SOURCE, which is
    #    the only thing this census measures (Rule 18). CQ compiles quantum
    #    sin/cos/tan TODAY at 6 of 9 widths, e2e-verified.
    **{c: ("decided-decline",
           f"openlibm BODY only (nested data-dependent-trip loops in k_rem_pio2.c; "
           f"CLAUDE.md Rule 18 names rem_pio2). THE FUNCTION IS COVERED AND SHIPS: "
           f"branchless/{c.split('.')[0]}.c + e2e slice_branchless_{c.split('.')[0]} "
           f"(registered in tests/e2e/CMakeLists.txt). Bennett backs it the same way "
           f"(branchless fsin.jl:468). Cell stays declined per the campaign honesty rule.")
       for c in ("sin.f64", "cos.f64", "tan.f64",
                 "sinl.f80", "cosl.f80", "tanl.f80")},
    #    The f32 trio is the SAME ruling but WITHOUT the shipped leaf — bd eur4.
    **{c: ("decided-decline",
           "openlibm BODY only (same k_rem_pio2.c loops; CLAUDE.md Rule 18 names rem_pio2). "
           "UNLIKE the f64/f80 six, NO branchless leaf exists at f32 for any function — "
           "so this width of the function is genuinely NOT covered yet. bd eur4.")
       for c in ("sinf.f32", "cosf.f32", "tanf.f32")},

    # -- ld80 gamma pair. NOT decided for the reason bd 20xt's 2026-07-24 comment
    #    gives ("no soft_lgamma in Bennett") — that premise is analytically WRONG
    #    (see README "THE GAMMA GATE"). The real, measured grounds are loops:
    "tgammal.f80": ("decided-decline",
                    "its OWN reduction loops ld80/e_tgammal.c:271/277/286, SCEV Unpredictable, quantum-governed trip"),
    "lgammal.f80": ("decided-decline",
                    "inherited Payne-Hanek via sinl: all 10 Unpredictable-BTC loops are in k_rem_pio2/rem_pio2l, none lgammal's own"),

    # -- THE ACTIONABLE SET (3 cells).
    #
    # RETIRED 2026-07-30 (bd 0rwu, PredMux W7): "expl.f80" and "log10l.f80" were
    # this table's only 2-cell lever and they now BOTH reach `opt` exit 0 — so they
    # are deliberately ABSENT rather than relabelled (a scope entry whose cell no
    # longer declines is a dead entry, and check_scope() fails loudly on one; that
    # is exactly how this edit was prompted). Their shared blocker was the fdlibm
    # __isnanl `&&` diamond (s_isnan.c:63), whose f80 merge phi is the INTEGER
    # `phi i32 [ 0, %entry ], [ %zext, %arm ]` — a const-fallthrough sole-phi
    # diamond that W5 left to the 4.2 value emitter and that the 4.2 emitter could
    # not take either (`Routed = StraightThrough` = the folded `0`; no accept path
    # matches a ConstantInt), so it declined `value-arm swap-route` at
    # ArmClassify.cpp:1171 with no owner anywhere. The W7 claim witness gives the
    # diamond to PredMux, which flattens it to the tainted `select` the 4.4/kjd1
    # controlled-copy merge already lowered. Both are e2e-VERIFIED, not merely
    # compiling (Rule 2): slice_libm_real_expl / slice_libm_real_log10l, strict
    # stage 2b. Measured effect on this census: injection-covered 95 -> 97,
    # declines 28 -> 26, and EXACTLY those two cells changed status (zero
    # regressions). NOTE log10l lands in `exit0-spec` (its `ldexpl` rides the
    # Phase-6 clone), not plain COMPILES — the two-numbers discipline says never
    # merge those buckets.
    "tgammaf.f32":    ("lever-gap",
                       "fcmp-conditioned fp select in a spec callee (isLiftableFpSelect requires ICmpInst, SpecializeReject.cpp:180-183); multi-lever, none owner-decided"),
    "tgamma.f64":     ("lever-gap",
                       "same single blocker as tgammaf.f32 (tgammaf is (float)tgamma(x)); its b_tgamma.c:200 loop is STATICALLY bounded (trip<=5) so Rule 18 keeps it IN scope"),
    "nexttowardf.f32":("lever-gap",
                       "promoteVolatileScalarLocals forfeits a STORE-ONLY alloca (Loads.empty(), QramLowering.cpp:1458); its 3 compiling siblings all read u. A control layer sits behind it"),

    # -- not this bucket's work.
    "powl.f80":       ("deferred-capability",
                       "by-ref out-param under specialization = the g387/7.5 Shadow axis, scoped OUT per bd 20xt"),
    "nexttowardl.f80":("corpus-gap",
                       "openlibm ships no s_nexttowardl.c. NB the recorded 'would land on nextafterl's blocker anyway' rider is REFUTED: nextafterl.f80 COMPILES today"),

    # -- the one cell the 2026-07-27 ruling did not cleanly reach; ADJUDICATED
    #    2026-07-28. Measured first: back-edge excision makes it lower COMPLETELY
    #    (opt exit 0, verify clean, zero residual @cq_*, NO deeper layer), and its
    #    loop recurrence is purely CLASSICAL (a counter + a shift register), so no
    #    dirty rail crosses the back edge and L3 §6-item-1 is structurally absent.
    #    Its TRIP COUNT is nevertheless quantum-dependent (SCEV Unpredictable on
    #    both loops). OWNER RULING: a quantum-dependent trip count is out
    #    REGARDLESS of the recurrence being classical — the strict reading of
    #    "only a QUANTUM-DEPENDENT one is out". So `8h7d`'s last census-facing
    #    cell is decided, and that epic is now a pure capability tracker.
    "logbl.f80":      ("decided-decline",
                       "owner ruling 2026-07-28: quantum-dependent trip count is out even with a purely CLASSICAL loop recurrence (strict read of the 2026-07-27 line)"),
}

def check_scope(results):
    """Rule-12 analog for the scope table: a stale SCOPE is a silent PLANNING
    miscompile, so drift fails loudly instead of being quietly carried forward."""
    declines = {k for k, v in results.items() if v["status"] == "decline"}
    missing  = sorted(declines - set(SCOPE))
    stale    = sorted(set(SCOPE) - declines)
    if missing:
        print(f"\n!! SCOPE INCOMPLETE — {len(missing)} declining cell(s) unclassified: {missing}")
        print("   Classify each before quoting any lever ranking off this census.")
    if stale:
        print(f"\n!! SCOPE STALE — {len(stale)} cell(s) no longer decline: {stale}")
        print("   Drop them from SCOPE (a decided-decline that now COMPILES is a dead entry).")
    return not (missing or stale)

def main():
    print("indexing openlibm corpus...", file=sys.stderr)
    defmap = WP.build_defmap()
    print(f"  {len(defmap)} syms / {len(list(WP.BC.glob('*.bc')))} bc", file=sys.stderr)
    results = {}
    buckets = defaultdict(list)
    n_cells = 0
    for spec in P.MATHH_SPEC:
        base = spec["base"]
        if base in KEEP: continue                 # hardware keep-set (recognition)
        if "macro" in spec["flags"]: continue      # not a real call
        if spec["backend"] == "n/a": continue      # by-design (nan)
        for v in spec["variants"]:
            width, ctype, suf, lit = VAR[v]
            spelling = base + suf
            args = cell_args(spec, width, ctype, lit)
            if args is None: continue
            rw = ret_width(spec, width)
            if rw is None: continue
            # ld80 f80 uses x86_fp80; sqrt-family keep already skipped.
            st, diag, src = WP.probe(spelling, rw, args, 0, defmap)
            b = bucket(st, diag)
            key = f"{spelling}.{width}"
            rec = {"status": st, "bucket": b, "diag": diag}
            if st == "decline" and key in SCOPE:
                rec["scope"], rec["scope_ref"] = SCOPE[key]
            results[key] = rec
            buckets[b].append(key)
            n_cells += 1
            print(f"  {spelling:12s} {width:4s} {b}", file=sys.stderr)
    json.dump(results, open("full_census_results.json","w"), indent=1)
    print(f"\n=== FULL-SURFACE CENSUS: {n_cells} injectable cells ===")
    comp = len(buckets.get("COMPILES", []))
    print(f"COMPILES: {comp}/{n_cells}   DECLINE: {n_cells-comp}/{n_cells}\n")
    print("BY BUCKET (what blocks it):")
    for b, fns in sorted(buckets.items(), key=lambda x: -len(x[1])):
        print(f"  {len(fns):3d}  {b}")
        print(f"       {', '.join(sorted(fns))}")
    # The axis that actually answers "where is the work?" — see SCOPE above.
    scopes = defaultdict(list)
    for k, v in results.items():
        if v["status"] == "decline":
            scopes[v.get("scope", "UNCLASSIFIED")].append(k)
    print("\nBY SCOPE (is it work?):")
    for s in ("lever-gap", "owner-ruling-needed", "deferred-capability",
              "corpus-gap", "decided-decline", "UNCLASSIFIED"):
        if s in scopes:
            print(f"  {len(scopes[s]):3d}  {s}")
            print(f"       {', '.join(sorted(scopes[s]))}")
    print(f"\nACTIONABLE LEVER GAP: {len(scopes.get('lever-gap', []))} cell(s) "
          f"of {n_cells - comp} declines. Quote THIS, not the decline count.")
    check_scope(results)

if __name__ == "__main__":
    main()
