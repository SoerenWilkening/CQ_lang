#!/usr/bin/env python3
# Full-surface injection census over every width, by-ref and int-ret cell. Imports probe.py's MATHH_SPEC as the
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
    """Census width of the cell's RETURN value. Never returns None: an
    unrecognized `ret` RAISES.

    bd bcv4 — this used to `return None` for anything that was not fp/long,
    with the comment "int-return macros — skipped", and main() turned that None
    into a silent `continue`. The comment misdescribed the only row it actually
    dropped: `ilogb` is a FUNCTION, not a macro (every genuine macro is already
    filtered by the `"macro" in spec["flags"]` test in main()). So ilogbf.f32 /
    ilogb.f64 / ilogbl.f80 were NEVER PROBED, while a function-level rollup read
    them as uncovered — the census reporting an unmeasured cell as a result.
    That is the same class of error as the six recorded bucket miscounts, in the
    opposite direction.

    The raise is the point, not the mapping. A silent skip is how a whole
    unmeasured row hides inside a number that gets quoted for planning, so a
    future `ret` kind must fail loudly here rather than shrink the denominator
    on its way past."""
    r = spec["ret"]
    if r == "fp":                return width
    if r == "int":               return "si32"   # ilogb — the only int-return fn
    if r in ("long", "llong"):   return "sl"
    raise ValueError(
        f"ret_width: unhandled ret={r!r} for base={spec['base']!r}. Add a width "
        f"mapping (and a wprobe.W entry if the C type is new) — do NOT skip it, "
        f"or the cell silently leaves the census denominator (bd bcv4).")

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
    #    design measured at ZERO cells: 9/9 have a loop SCEV cannot bound at all
    #    — *** that "9/9" is AS-MEASURED 2026-07-27 and is now 7/9: see the
    #    remainderl/remquol entry below, whose bodies changed under bd 3c6m.63 and
    #    which no longer block on a loop at all. The CONCLUSION (payoff zero) is
    #    unchanged and in fact strengthened for those two — they block EARLIER. ***
    **{c: ("decided-decline", "SCOPING-L3-data-dependent-trip-loops.md (owner 2026-07-27); re-open only via its §6")
       for c in ("fmod.f64", "fmodf.f32", "fmodl.f80",
                 "remainder.f64", "remainderf.f32",
                 "remquo.f64", "remquof.f32")},
    #    TWO OF THE NINE NO LONGER BLOCK ON A LOOP — corrected 2026-08-23 (bd
    #    `3c6m.63`, the corpus-collision fix). The RULING IS UNTOUCHED: its Leg A
    #    ("Bennett ships NO frem/fmod algorithm at ANY width") is body-independent
    #    and grounds all nine. What is falsified is the block comment's EVIDENCE
    #    line "9/9 have a loop SCEV cannot bound at all" — true of the ld80 bodies
    #    the census used to measure, and NOT re-measured for these two on the
    #    bodies openlibm actually builds. Both now block BEFORE any loop, on the
    #    same instruction, and the loop behind it is UNMEASURED. Recording the
    #    stale line would be exactly the unverifiable scope_ref this table exists
    #    to retire (the tgammal.f80 precedent below).
    **{c: ("decided-decline",
           "SCOPING-L3-data-dependent-trip-loops.md (owner 2026-07-27); re-open only via its §6. "
           "RULING STANDS on Leg A (Bennett ships no frem/fmod gate sequence at any width — "
           "body-independent) but its EVIDENCE LINE IS CORRECTED 2026-08-23 (bd 3c6m.63): on the "
           "body openlibm actually builds (src/s_remquol.c, not the ld80 variant the corpus used "
           "to reach through a basename collision) the measured first blocker is NOT a loop at "
           "all — it is `src/s_remquol.c:76:7 ux.e = x`, the union IEEEl2bits store, i.e. "
           "`cq taint escape: tainted value stored to memory` = the 3c6m.51 promoteFp80Union / "
           "7.5 Shadow axis. Bucket moved loop-carried -> memory-store (Shadow). The loop the "
           "ruling's payoff sizing cites is BEHIND that store and is now UNMEASURED on this body; "
           "do NOT quote '9/9 have a loop SCEV cannot bound' for these two")
       for c in ("remainderl.f80", "remquol.f80")},

    # -- sin/cos/tan x3 widths: Payne-Hanek. What is ruled out is openlibm's
    #    SOURCE FORM — k_rem_pio2.c's nested data-dependent loops (owner decision
    #    2026-07-27; CLAUDE.md Rule 18 named "Payne-Hanek `rem_pio2`").
    #    The f32/f64 bucket split is a pure SROA artifact: e_rem_pio2f.c:47
    #    `double tx[1]` promotes to SSA while e_rem_pio2.c:55 `double tx[3]`
    #    survives, so the f32 trio blocks one call DEEPER (inside k_rem_pio2)
    #    on the @ipio2 QROM read instead of on the tx fill store. Same capability.
    #    *** READ THE scope_ref, NOT THE CELL NAME. *** This census measures
    #    openlibm's body only. A user's quantum sin/cos/tan on a DOUBLE lowers to one
    #    Bennett-backed template call (bd 3c6m.71), so the f64 function is covered
    #    through cqc. The f32 and f80 widths have no backend route (Bennett has no
    #    binary32 or x87 version) and are NOT covered. CQ's own branchless leaves
    #    that once covered f64/f80 were retired 2026-10-06 (bd 3c6m.78): CQ ships
    #    no C implementation of a library function.
    **{c: ("decided-decline",
           "openlibm BODY only (nested data-dependent-trip loops in k_rem_pio2.c; owner "
           "2026-07-27). The f64 function lowers through cqc by its direct Bennett-backed "
           "template (bd 3c6m.71); this cell does not measure that route.")
       for c in ("sin.f64", "cos.f64", "tan.f64")},
    **{c: ("decided-decline",
           "openlibm BODY only (same k_rem_pio2.c loops; owner 2026-07-27). No backend "
           "route exists at this width, so the function is NOT covered (bd 3c6m.79).")
       for c in ("sinf.f32", "cosf.f32", "tanf.f32", "sinl.f80", "cosl.f80", "tanl.f80")},

    # -- ld80 gamma pair. NOT decided for the reason bd 20xt's 2026-07-24 comment
    #    gives ("no soft_lgamma in Bennett") — that premise is analytically WRONG
    #    (see README "THE GAMMA GATE"). The real, measured grounds are loops:
    # BOTH REFS RE-MEASURED 2026-07-31 (bd guwr) — and both were describing a
    # blocker the pass does not actually hit first. Keep the ruling, fix the
    # evidence: an unverifiable scope_ref is exactly the assertion this table
    # exists to retire.
    # THE "behind stirf" CLAUSE WAS HALF WRONG — corrected 2026-08-21 from bd 19v3
    # §4c, which located this cell's blocker to the INSTRUCTION for the first time.
    # The cell has FOUR loops at the module the pass reaches, and they are not one
    # population:
    #   * the trip-33 `@powil` loop (openlibm's binary-exponentiation
    #     `while(n){ ww*=ww; if(n&1) y*=ww; n>>=1; }`, e_powl.c:626-634) genuinely
    #     DOES sit behind `stirf` — and it reaches NOTHING, for three independent
    #     and individually sufficient reasons: `@powil` has 0 tainted defs so
    #     `lowerLoops`'s AnyTainted gate skips it; its exit condition
    #     `icmp ult i32 %66, 4` is CLASSICAL, so it is not a quantum-bounded loop
    #     at all in the module the pass sees; and the cell's first blocker precedes
    #     `lowerLoops` entirely. (Its `!dbg` line is 0 because rotation merged the
    #     preheader and the in-body `n >>= 1`; the true line survives on
    #     `!llvm.loop` as e_powl.c:628.)
    #   * the THREE `ld80/e_tgammal.c:271/277/286` reduction loops the ruling
    #     actually names are in `@probe`, on the OTHER ARM of the tainted branch
    #     `q > 13.0` — MUTUALLY EXCLUSIVE with the `stirf` arm, not behind it. They
    #     are 3 of the 5 fp-condition CouldNotCompute loops in bd 19v3 §2f and are
    #     still UNMEASURED, so the ruling's own evidence is still unverified.
    "tgammal.f80": ("decided-decline",
                    "RULING STANDS (its own reduction loops ld80/e_tgammal.c:271/277/286, SCEV "
                    "Unpredictable, quantum-governed trip). MEASURED 2026-10-06 (bd 3c6m.78): the "
                    "first blocker is openlibm's `sinl` again (unsupported instruction), since CQ's "
                    "own sinl leaf was retired. History: that is NOT the "
                    "blocker the ruling names, and was not on the 2026-07-30 baseline either: pre-amendment it "
                    "blocked at `sinl` (unsupported instruction), post-amendment at `stirf` "
                    "(unsupported instruction) — the CQ-provided sinl cleared the sinl layer. "
                    "CORRECTED 2026-08-21 (bd 19v3 §4c): 'the loops sit behind stirf' is HALF "
                    "WRONG — only the trip-33 @powil loop does (and it reaches nothing: 0 tainted "
                    "defs, classical exit, and the first blocker precedes lowerLoops), while the "
                    "three e_tgammal.c:271/277/286 reduction loops are in @probe on the OTHER ARM "
                    "of the tainted branch q > 13.0, mutually exclusive with the stirf arm rather "
                    "than behind it — and still UNMEASURED. The first blocker is now identified to "
                    "the instruction: `%7 = alloca i32`, the int* out-param slot for frexpl(x,&e) "
                    "in the inlined powl body = the g387/7.5 by-ref Shadow axis, the same axis "
                    "lgammal.f80's ref already names"),
    # RE-SCOPED 2026-08-10 by owner ruling, re-measured 2026-10-06. The 2026-08-10
    # entry rested on CQ-provided sinl/cosl leaves and weighed admitting a CQ `logl`
    # leaf; both ideas are retired (bd 3c6m.78: CQ ships no C implementation of a
    # library function). Measured now: the first blocker is openlibm's `sinl`
    # (Payne-Hanek, unsupported instruction), the same blocker as the f80 trig
    # cells (bd 3c6m.79). Behind it, ld80/e_logl.c at -O1 carries an `alloca i32`,
    # two `store i32` into it and a by-ref `call @frexpl(x86_fp80, ptr)` — the
    # g387/7.5 by-ref out-param axis that owns powl.f80. Depth behind that is
    # UNMEASURED; this table has mispredicted the next layer three times running on
    # the adjacent gamma pair.
    "lgammal.f80": ("decided-decline",
                    "first blocker openlibm `sinl` (Payne-Hanek k_rem_pio2l loops, owner "
                    "2026-07-27; no backend route at f80, bd 3c6m.79), measured 2026-10-06. "
                    "Behind it: in-clone control in logl and the g387/7.5 by-ref frexpl axis — "
                    "depth UNMEASURED"),

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
    # bd tkmn Inc 1 (2026-07-30) CLEARED the fcmp-select layer these two entries
    # used to name. Their FIRST blocker is now the Payne-Hanek scratch alloca in
    # `sin`, which corrects the recorded LAYER ORDER: the ticket predicted the
    # b_tgamma.c:200 loop and the :309/311 recursion behind the select, but BOTH
    # sit behind `sin` and remain UNMEASURED (never reached). Still lever-gap and
    # NOT decided-decline — the blocking path is mathematically dead here, which
    # is a pruning capability we have not built, not an owner ruling.
    # ADVANCED ONE LAYER 2026-07-31 (bd guwr). The Payne-Hanek `sin` blocker these
    # two carried since bd tkmn is GONE — CQ's own branchless sin is injected now,
    # so the `iq[20]` scratch alloca never enters the module and the fp-range
    # DEAD-PATH PRUNING capability is no longer needed to move these cells.
    # And for the THIRD time on this pair the next layer was NOT what the record
    # predicted: neither the b_tgamma.c:200 loop nor the :309/311 depth-1
    # recursion, but a struct-valued fp return under Phase-6 specialization.
    # Do not quote the loop or the recursion as known-remaining; they are still
    # UNMEASURED, now behind `large_gam`.
    # RE-MEASURED 2026-10-06 (bd 3c6m.78): CQ's own sin leaf is retired, so THIS
    # census (openlibm bodies only) blocks at openlibm's `sin` again. Through cqc
    # the bundle forwards `sin` to its direct Bennett-backed route, and a quantum
    # tgamma(q) there stops at `__log__D { double, double } (double)` (b_log.c:440):
    # the same aggregate fp-return layer `large_gam` showed.
    "tgammaf.f32":    ("lever-gap",
                       "here: openlibm `sin` (unsupported instruction; cqc takes the direct route "
                       "instead). The layer behind it, and cqc's first blocker: "
                       "`large_gam`/`__log__D { double, double } (double)`: cq specialization: floating-point "
                       "quantum argument or return has no reversible copy — an AGGREGATE-typed fp "
                       "return under quantum lift. Needs multi-value/struct return support in the "
                       "Phase-6 specializer (or SROA-ing the pair), NOT the fp-range pruning the "
                       "previous ref named"),
    "tgamma.f64":     ("lever-gap",
                       "same blockers as tgammaf.f32 (tgammaf is (float)tgamma(x)): openlibm `sin` "
                       "here, then (cqc's first blocker) `large_gam`/`__log__D`'s "
                       "{double,double} return is the layer; b_tgamma.c:200's bounded loop and the "
                       "depth-1 self-recursion sit BEHIND it and are still UNMEASURED"),
    # RETIRED 2026-08-10 (bd k710 SPENT): "nexttowardf.f32" now reaches `opt` exit
    # 0 and is deliberately ABSENT rather than relabelled — a scope entry whose
    # cell no longer declines is a dead entry and check_scope() fails loudly on
    # one (the same convention the 0rwu pair left behind). Its blocker was the
    # store-only `volatile float u = x*x;` at ld80/s_nexttowardf.c:63, cleared by
    # the fenv ruling + eraseDeadVolatileScalarStores.
    #
    # TWO THINGS THE OLD ENTRY GOT WRONG, both corrected on the ticket: it said
    # "its 3 compiling siblings all read u" — there are FOUR (nextafter{,f,l} +
    # nexttoward) and three of them name the scalar `t`; and "A control layer sits
    # behind it" was STALE peel data from f92ba9f (2026-07-14), predating the
    # PredMux work. Re-measured, nothing sits behind it: the cell lands.

    # -- not this bucket's work.
    "powl.f80":       ("deferred-capability",
                       "by-ref out-param under specialization = the g387/7.5 Shadow axis, scoped OUT per bd 20xt"),

    # =======================================================================
    # -- THE nextafterl/nexttoward FOUR — *** LANDED 2026-08-23 (bd `3c6m.67`).
    #    NO SCOPE ENTRIES BELOW; ALL FOUR NOW COMPILE. Injection 97 -> 101/120.
    # =======================================================================
    # THE ENTRIES ARE GONE ON PURPOSE — a `decided-decline`/`deferred-capability`
    # that now COMPILES is a dead entry and `check_scope()` fails loudly on it
    # (SCOPE STALE), which is exactly how this landing was confirmed. What is kept
    # is the ANALYSIS, because it is the only place the two-source-family story is
    # written down and re-deriving it cost two sessions.
    #
    # WHAT HAPPENED, IN ORDER, BECAUSE THE SEQUENCE IS THE LESSON:
    #  (1) Until 2026-08-23 the census built ten openlibm TUs from `ld80/` whose
    #      basenames also exist in `src/`, and openlibm's build EXCLUDES all ten.
    #      Three of these cells were scored `COMPILES` ON A BODY THAT SHIPS
    #      NOWHERE and the fourth was reported as having no body (bd `3c6m.63`).
    #      Correcting the corpus took injection 100 -> 97/120.
    #  (2) That correction EXPOSED a real gap rather than creating one. All four
    #      shared ONE blocking construct — and NOT the one the diagnostic named.
    #  (3) bd `3c6m.67` fixed the construct. All four now COMPILE, on the bodies
    #      openlibm actually builds, each with a committed ship-floor golden
    #      (`tests/e2e/slice_libm_real_next*`), which is the standard bd `3c6m.63`
    #      set for a landing: the census number and the `verified` glob count must
    #      move together or `e2e-census-slice-sync` fires.
    #
    # *** THE DIAGNOSTIC POINTED AT THE WRONG LINE FOR THREE OF THE FOUR, AND THAT
    # IS THE PART WORTH REMEMBERING. *** It named the NaN guard (:42:29 / :44:22),
    # which invites "the nested `&&` is the problem". REFUTED by the ld80 twins:
    # they carry the BYTE-IDENTICAL two-level `&&`/`||` guard with the same
    # post-promotion CFG topology and lower at exit 0. The guard was merely the
    # OUTERMOST region, and read as *nested* only because a region below it
    # survived as live control flow.
    #
    # THAT REGION WAS THE ulp-DIRECTION TEST — the one place the two source
    # families genuinely differ:
    #     ld80 (always lowered): an INTEGER word ladder —
    #                            ix>iy || ((ix==iy) && (hx>hy …))
    #     src  (declined):       an XOR OF TWO COMPARES on the tainted value —
    #                            if((x>0.0)  ^ (x<y))   src/s_nextafterl.c:55
    #                            if((hx>0.0) ^ (x<y))   src/s_nexttoward.c:54
    #                            if((hx>=0)  ^ (x<y))   src/s_nexttowardf.c:45
    # `nexttowardl.f80` IS nextafterl (`openlibm_strong_reference` at :80), so it
    # was never a separate construct — or, as its old `corpus-gap` entry claimed,
    # a missing body.
    #
    # `nexttowardf.f32` declined FLAT rather than nested only because its `^`
    # diamond is the OUTERMOST region there (PredMux never invoked, 0 leaves).
    # Same construct, different bucket, purely positional — reading that split as
    # two problems would have been a scoping error.
    #
    # TWO SUPERSEDED READINGS, kept so neither is re-derived:
    #  * "nextafter.f64/nextafterf.f32 COMPILE while nextafterl.f80 does not, so
    #    the difference is at least partly the fp80 union / width dimension" —
    #    WRONG. Those two come from src/s_nextafter{,f}.c, which use the
    #    INTEGER-WORD form. It was the CONSTRUCT, never the width. A width-shaped
    #    investigation would have been wasted.
    #  * bd `k710`'s +1 for `nexttowardf.f32` (97->98, 2026-08-10) stays RETRACTED
    #    even though the cell is covered again. It rested on the write-only
    #    `volatile float u = x*x;` at ld80/s_nexttowardf.c:63 and the fenv ruling;
    #    src/'s scalar `t` IS READ, so that path is never reached in the shipped
    #    body. The cell re-earns its place on the xor, on a different mechanism.
    #    The fenv ruling and `eraseDeadVolatileScalarStores` are UNAFFECTED.
    #
    # AND THE SCOPE-AXIS LESSON, which the axis exists for: these four sat at
    # `deferred-capability` and NOT `lever-gap` because the depth BEHIND the named
    # first blocker was unmeasured, and this table had mispredicted the next layer
    # three times running on the tgamma pair. Measuring it first (a structural
    # probe that rewrote ONLY the xor into an in-grammar and/or tree, with
    # complementary compare leaves so no xor node existed anywhere) showed the
    # depth was ZERO — all four went straight to COMPILES. The conservative label
    # cost one measurement and prevented a fifth misprediction; it did not cost
    # the cells.
    # =======================================================================
    # THE PER-CELL MEASUREMENT, retained verbatim from the pre-landing entry
    # because it is the evidence for everything above and nothing else records it
    # (CQ_PREDMUX_DBG / CQ_CTRL_DBG, both corpora, 2026-08-23):
    #   nextafterl.f80   PredMux asked 16x, LEAVES all 16; the root it declined was
    #                    the `^` branch at :55, gate E6-condtree (+ E3-sideentry /
    #                    E3-mergepred on the rest). ControlDetect then declined the
    #                    enclosing NaN guard as nested, reported at :42:29.
    #   nexttoward.f64   same shape, root at :54, gate E6-condtree; reported :44:22.
    #   nexttowardf.f32  PredMux NEVER INVOKED (0 leaves) — the `^` diamond at :45:5
    #                    WAS the region and declined FLAT. Same construct, different
    #                    bucket, purely because here it is outermost.
    #   ld80 twins       nextafterl: PredMux 0 leave / 0 claim — never consulted at
    #                    all, ControlDetect claimed the integer ladder directly. All
    #                    three ld80 bodies: opt exit 0, which is what refuted the
    #                    NaN-guard reading.
    # Corpus provenance of the numerator move, so neither step is misread: the
    # ld80/src collision fix took injection 100 -> 97/120 (a CORRECTION — the number
    # had been measuring a program that ships nowhere, `165/174` caught again), and
    # bd 3c6m.67 then took it 97 -> 101/120 (real compiler work). Those are two
    # different kinds of change and must never be netted into "+1".

    # =======================================================================
    # -- THE ilogb/logb QUANTUM-TRIP FAMILY — 2 + 2, NOT 4 (RE-SCOPED 2026-08-21)
    # =======================================================================
    # These four cells carried ONE label from 2026-08-10 to 2026-08-21 and it is
    # now measured that they do not belong together. The split is the whole point
    # of this block; do not re-merge them.
    #
    # HISTORY, so the change of ground is legible rather than looking like drift:
    #   2026-07-28  owner ruling — "a quantum-dependent trip count is out EVEN
    #               WHEN the loop recurrence is purely classical ... the test is
    #               the TRIP COUNT alone". `logbl.f80` IS that ruling's worked
    #               example. All four sat here as `decided-decline`.
    #   2026-08-21  owner ruling on bd `eyhj` — **GO, NARROWED TO DERIVATION**:
    #               a quantum-dependent trip count is ADMISSIBLE when the compiler
    #               PROVES a quantum-independent upper bound B *from the IR in
    #               front of it* and emits the loop ROLLED at classical trip count
    #               B with a body predicated on a quantum still-running flag.
    #               Failure to derive is a loud decline. A DERIVATION, never a
    #               PARAMETER: an undersized bound becomes UNREACHABLE rather than
    #               undetected, because failing to derive is a decline.
    #               => the 2026-07-28 ruling no longer grounds ANY of these four,
    #                  and the two halves move in OPPOSITE directions.
    # Evidence: bd `8zj2` (8 cells) + bd `19v3` (whole census), memos
    # `SPIKE-8zj2-ilogb-logb-loop-bounds.md` / `SPIKE-19v3-loop-bound-population.md`,
    # bd memory [narrowed-quantum-trip-rule-2026-08-21].
    #
    # ---- HALF ONE: LANDED 2026-08-22 (bd ww4c.3) — NO LONGER A SCOPE ENTRY ----
    #    src/s_ilogb.c:40   for (ix = -1043; lx>0; lx<<=1) ix -=1;
    #    src/s_ilogb.c:42   for (ix = -1022,hx<<=11; hx>0; hx<<=1) ix -=1;
    #    src/s_ilogbf.c:35  for (ix = -126,hx<<=8; hx>0; hx<<=1) ix -=1;
    #
    #    `ilogb.f64` and `ilogbf.f32` COMPILE. They are deliberately ABSENT from
    #    SCOPE rather than relabelled: SCOPE classifies DECLINES, and
    #    `check_scope()` reports a covered cell that still carries an entry as
    #    STALE — which is the whole point of that gate ("a decided-decline that
    #    now COMPILES is a dead entry"). Leaving a triumphant `lever-gap` note
    #    here would be exactly the silent PLANNING miscompile it exists to catch.
    #    The history is kept HERE, in the comment, because the ticket trail is
    #    worth more than the label was.
    #
    #    WHAT CLEARED THEM: bd `ww4c`, the loop->`llvm.ctlz` idiom recognizer
    #    (`ir-pass/src/CtlzIdiomPrepass.cpp`, fence Z1-Z9), licensed as INJECTION
    #    coverage by the owner ruling of 2026-08-22 — "yes, it counts as injection
    #    coverage — the body stays openlibm's". It rewrites the rotated do-while
    #    to the closed form `(C0-1) - (ctlz_N(v<<1) & (N-1))`: four ops, zero new
    #    frozen symbols, and NO loop survives, so the eyhj bound-derivation ruling
    #    is not needed for these two at all. bd `m57l` (roll at B=33 + predicated
    #    body) was NOT chosen and is deferred, not dead.
    #
    #    MEASURED AT LANDING, not predicted (bd ww4c.3, corpus fingerprint
    #    409 syms / 251 bc — *** that is the PRE-3c6m.63 DEFECTIVE fingerprint;
    #    the faithful one is 410/252. Neither ilogb cell is affected: their bodies
    #    are src/s_ilogb{,f}.c, which no ld80 file collides with, and both were
    #    re-measured COMPILES on the corrected corpus 2026-08-23 ***): both cells
    #    move `decline/loop-carried` -> `COMPILES`
    #    under this census's own O1 pipeline, and a whole-census A/B against the
    #    prior baseline moved EXACTLY these two with ZERO regressions. Both ship
    #    with committed ship-floor goldens at stage-2b STRICT
    #    (`tests/e2e/slice_libm_real_ilogb{,f}.c`; 46/46 and 18/18 free-pairing
    #    verified, 0 unproven), so injection-covered and verified moved together.
    #    The closed form was re-swept exhaustively over all 2^32 inputs at the
    #    SHIPPED constants: 0 mismatches, true worst trips 31/20/23 — which
    #    independently reproduces the 31/20/23 recorded against the old 33 ceiling.
    #
    #    THE OTHER TWO CELLS THAT LOOK LIKE THESE STILL DECLINE, BY FENCE AND NOT
    #    BY LUCK — see HALF TWO. `ilogbl.f80`/`logbl.f80` shift a MASK and compare
    #    a DERIVED value, so they fail Z5, and their counter INCREMENTS, so they
    #    also fail Z4. Both were re-measured `loop-carried` in the same run.
    #
    #    NOT REACHED, and this was measured rather than hoped: bd `19v3` put this
    #    pair at the ENTIRE bucket-(A) population, so the payoff is 98 -> 100 and
    #    no more. fmod.f64 / remainder.f64 / remquo.f64 only LOOK adjacent — their
    #    blocker stack is four loops deep and the back two are vacuous
    #    (constant-max -2) or CouldNotCompute.

    # ---- HALF TWO: NO bound is derivable -> deferred-capability, NOT decided ----
    #    src/s_logbl.c:36  == src/s_ilogbl.c:37   for (b = LDBL_MANH_SIZE; !(u.bits.manl & m); m >>= 1)
    #    src/s_logbl.c:40  == src/s_ilogbl.c:41   for (b = 0;              !(u.bits.manh & m); m >>= 1)
    #    THREE corrections to what this block used to say (bd 0bp8, all measured):
    #    (a) The old ref's bridging clause "f64/f32 are the same idiom in their own
    #        spelling" is FALSE, and the difference is exactly what flips the
    #        answer: f64/f32 shift the DATA and test its SIGN (SCEV bounds it at
    #        i32 32, totally); f80 shifts a MASK and tests an `and`
    #        (CouldNotCompute, and genuinely non-terminating on 2 inputs).
    #    (b) There are TWO loops per cell, not one, and BOTH pairs are
    #        byte-identical across the sibling files — but the pair the old ref
    #        CITED (:36/:37) is NOT the pair either cell declines on. The shipped
    #        first blockers are `s_ilogbl.c:41:4` and `s_logbl.c:40:4`, the OTHER
    #        pair. (Every recorded diagnostic is a FIRST BLOCKER ONLY.)
    #    (c) The recorded bounds "<=31 / <=23 / <=64 iterations": f64 (31) and f32
    #        (23) are exactly right; the f80 "<=64" is WRONG. Each f80 loop runs
    #        <=31 trips on the GUARD-ADMITTED domain and does not terminate at all
    #        on 2 of 2^32 inputs once the guard is gone. 64 appears to have been
    #        read off the mantissa width; the closest real quantity is the COUNTER
    #        `b`, which reaches 63.
    #    WHY THEY ARE DEFERRED AND NOT RE-DECLINED: their ground CHANGED. It is no
    #    longer the 2026-07-28 parity ruling, it is "no derivable bound exists" —
    #    CouldNotCompute on both loops at every SCEV query under 12 pipelines
    #    incl. default<O2>/<O3> and on the post-promoteFp80Union module the pass
    #    analyses, and SCEV is CORRECT there, not conservative. Recording them as
    #    decided-decline after a GO ruling would be exactly the stale-scope
    #    planning miscompile check_scope() exists to catch.
    #    THEIR SAFETY TODAY IS AN ACCIDENT and that is the load-bearing fact:
    #    SCEV reports nothing, so no unsound bound can be built from it. The only
    #    bound that exists is GUARD-CONDITIONAL on a TAINTED guard, so the
    #    "shift-until-normalized" recognizer of SCOPING-L3 §6 item 1 would recover
    #    it and WOULD be a silent miscompile — bd `k02s` is its precondition.
    #    THE OLD RE-OPENING MECHANISM IS DEAD, measured and stronger than bd eyhj
    #    stated: the shipped LoopUnrollPrepass VISITS these loops and claims NONE,
    #    failing U3, U5 AND U6, and U6 is decisive STRUCTURALLY rather than by its
    #    cap — it demands the EXACT trip count (LoopUnrollPrepass.cpp:199), which a
    #    quantum-dependent trip count cannot have. Raising kMaxUnrollTrip from 8 to
    #    33 would change NOTHING. (That LoopUnrollPrepass claim IS four-cell — the
    #    CQ_UNROLL_DBG probe was silent on all four.) Stock LLVM 19 also leaves both
    #    back edges intact under -unroll-max-upperbound=64, -unroll-count=33
    #    -unroll-allow-partial -unroll-runtime, -unroll-force-peel-count=33 and
    #    default<O3> — but that one is MEASURED ON ilogb.f64 ONLY (bd eyhj). The f80
    #    pair was never run under those flags, and it could not be: -unroll-count=33
    #    and -unroll-max-upperbound=64 both presuppose a constant max BTC these two
    #    cells do not have. Do not quote it as an f80 result — that would be exactly
    #    the f64->f80 bridging this block's correction (a) above retires.
    **{c: ("deferred-capability",
           "DEFERRED 2026-08-21 by the owner GO on bd eyhj ('the others that cannot be compiled that "
           "way, such as ilogbl will be tackled later') — tracker bd ywws. NOT decided-decline: the "
           "2026-07-28 parity ruling is NO LONGER the ground. New ground = 'no derivable bound "
           "exists', measured: CouldNotCompute on BOTH loops at every SCEV query under 12 pipelines "
           "and on the post-promoteFp80Union module, and that is CORRECT not conservative — on the "
           "rotated IR body 2 inputs (0, 0x80000000) never terminate. The only bound available is "
           "GUARD-CONDITIONAL on a TAINTED (manl|manh)!=0 guard that PredMux removes, so the "
           "SCOPING-L3 §6 item 1 recognizer that would recover it is a silent-miscompile shape (bd "
           "k02s). Safety today is an ACCIDENT of SCEV reporting nothing. NOT re-openable by a "
           "static-K unroll: LoopUnrollPrepass visits these loops and claims none, failing U3/U5/U6, "
           "and U6 demands the EXACT trip count (LoopUnrollPrepass.cpp:199) — raising kMaxUnrollTrip "
           "8->33 changes NOTHING. bd ww4c's ctlz recognizer does not reach them either — and "
           "as of 2026-08-22 that is MEASURED rather than predicted (bd ww4c.3: both cells "
           "re-probed `decline / loop-carried` in the same run that moved ilogb.f64/ilogbf.f32 "
           "to COMPILES). CORRECTED GROUND, because the prediction named the wrong fence: it is "
           "NOT is_zero_poison (the emitted ctlz is TOTAL, so the divergent inputs {0, "
           "0x80000000} would need no excluding). It is Z5 — these shift a MASK (`lshr` of the "
           "induction variable) and compare a DERIVED value (`and <rec>, <invariant data>`) with "
           "predicate `eq`, where Z5 demands `icmp sgt <the recurrence's own latch value>, 0` — "
           "AND Z4, because their counter INCREMENTS. Two independent grounds, which is exactly "
           "the defence-in-depth PRD-ww4c §5.1 argues for")
       for c in ("ilogbl.f80", "logbl.f80")},
}

# The vocabulary of the `scope` field, enforced below. bd 0bp8 asked whether the
# deferred ilogbl/logbl pair needed a NEW bucket: it does not — `deferred-capability`
# already means "real, not owner-ruled out, and not this lever's work", which is
# exactly their position — but the ANSWER only holds because the label now names a
# tracker (bd ywws). A `deferred-capability` with no capability behind it is the same
# unfalsifiable assertion as a `decided-decline` with no citation.
VALID_SCOPES = ("lever-gap", "owner-ruling-needed", "deferred-capability",
                "corpus-gap", "decided-decline")

def check_scope(results):
    """Rule-12 analog for the scope table: a stale SCOPE is a silent PLANNING
    miscompile, so drift fails loudly instead of being quietly carried forward."""
    # bd keol: a `no-body` cell was never probed, so it is not a DECLINE — but it
    # still carries (and still needs) a SCOPE entry, because "openlibm ships no
    # body for this" is exactly a `corpus-gap` scope. Counting it here keeps the
    # keol classification from reading as SCOPE STALE the moment it starts firing.
    declines = {k for k, v in results.items()
                if v["status"] in ("decline", "no-body")}
    missing  = sorted(declines - set(SCOPE))
    stale    = sorted(set(SCOPE) - declines)
    # bd 0bp8 — the THIRD drift direction, which this function did not check and
    # which the BY SCOPE report silently swallows: a label that is not in the
    # vocabulary. The report loop iterates a hardcoded tuple, so a typo'd or
    # newly-invented label prints NOWHERE and the cell vanishes from the "is this
    # work?" axis entirely — the failure mode is a cell that looks classified in
    # the JSON and is absent from every ranking read off this census. Both ends are
    # checked against the SAME tuple so they cannot drift apart (Rule 14).
    badlabel = sorted(f"{k}={v[0]}" for k, v in SCOPE.items() if v[0] not in VALID_SCOPES)
    if badlabel:
        print(f"\n!! SCOPE VOCABULARY — {len(badlabel)} entr(ies) use a label that is not "
              f"one of {VALID_SCOPES}: {badlabel}")
        print("   Add the label to VALID_SCOPES *and* to the BY SCOPE report tuple, or fix "
              "the entry. An unlisted label is invisible in every lever ranking.")
    if missing:
        print(f"\n!! SCOPE INCOMPLETE — {len(missing)} declining cell(s) unclassified: {missing}")
        print("   Classify each before quoting any lever ranking off this census.")
    if stale:
        print(f"\n!! SCOPE STALE — {len(stale)} cell(s) no longer decline: {stale}")
        print("   Drop them from SCOPE (a decided-decline that now COMPILES is a dead entry).")
    return not (missing or stale or badlabel)

def main():
    print("indexing openlibm corpus...", file=sys.stderr)
    defmap = WP.build_defmap()
    print(f"  {len(defmap)} syms / {len(list(WP.BC.glob('*.bc')))} bc", file=sys.stderr)
    results = {}
    buckets = defaultdict(list)
    n_cells = 0
    missing_entry = []        # bd keol — cells whose OWN body is not in the corpus
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
            # ld80 f80 uses x86_fp80; sqrt-family keep already skipped.
            key = f"{spelling}.{width}"

            # --- bd keol: THE CELL'S OWN ENTRY SYMBOL MUST BE IN THE CORPUS ---
            # A missing .bc does not fail loudly on its own. The probe's call to
            # `spelling` simply stays an unresolved external, survives inlining,
            # and the pass reports "unknown callee" — a TRUE diagnostic about a
            # FAKE situation, which then masks the cell's real first blocker.
            # That failure mode produced FIVE wrong bucket counts on this
            # campaign (the vuy6 module-asm aliases, the 6 missing TUs, the ld80
            # ieee.h retraction), and every one was found by hand, late.
            #
            # This is deliberately NOT a hard abort: a real corpus gap must not
            # stop the whole census, and it is now classified by the HARNESS,
            # from the corpus, instead of being inferred from a compiler
            # diagnostic that cannot tell the two apart.
            #
            # *** AS OF 2026-08-23 THIS BRANCH HAS NO CUSTOMER, and how it lost
            # its only one is the point (bd `3c6m.63`). `nexttowardl.f80` was the
            # standing example — "openlibm ships no s_nexttowardl.c at all" — and
            # that was FALSE: openlibm mints the name as
            # `openlibm_strong_reference(nextafterl, nexttowardl)` at
            # src/s_nextafterl.c:80, which the bd-`vuy6` alias shim resolves. The
            # census could not see it because a basename collision made
            # ld80/s_nextafterl.c win the output slot, and THAT file has the alias
            # COMMENTED OUT (ld80/s_nextafterl.c:90). So this classification was
            # reporting a CORPUS-RECIPE defect as an UPSTREAM one. Keep the branch
            # — it is a live guard — but do not read a `no-body` cell as proof
            # that upstream ships nothing; check `build_corpus.py` first. ***
            if spelling not in defmap:
                missing_entry.append(key)
                rec = {"status": "no-body", "bucket": "corpus-gap (no body)",
                       "diag": f"{spelling}: no definition in the corpus defmap "
                               f"— NOT PROBED, so this cell has no measured "
                               f"blocker (bd keol)"}
                if key in SCOPE:
                    rec["scope"], rec["scope_ref"] = SCOPE[key]
                results[key] = rec
                buckets["corpus-gap (no body)"].append(key)
                n_cells += 1
                print(f"  {spelling:12s} {width:4s} CORPUS-GAP (no body — not probed)",
                      file=sys.stderr)
                continue

            st, diag, src = WP.probe(spelling, rw, args, 0, defmap)
            b = bucket(st, diag)
            rec = {"status": st, "bucket": b, "diag": diag}
            if st == "decline" and key in SCOPE:
                rec["scope"], rec["scope_ref"] = SCOPE[key]
            results[key] = rec
            buckets[b].append(key)
            n_cells += 1
            print(f"  {spelling:12s} {width:4s} {b}", file=sys.stderr)
    # Write DIRECTLY to the opt-level-named authoritative baseline, in this
    # script's own directory. This used to write a fixed "full_census_results.json"
    # into the CWD and the real baseline (full_census_O1.json) was produced by a
    # MANUAL RENAME — and that manual step is where the artifact family drifted
    # apart every time (bd o22d / eyfm: a stale duplicate quoted for planning is a
    # silent PLANNING miscompile). No rename step means no drift.
    out = Path(__file__).resolve().parent / f"full_census_{WP.CENSUS_OPTLEVEL}.json"
    json.dump(results, open(out, "w"), indent=1)
    print(f"wrote {out.name}", file=sys.stderr)
    print(f"\n=== FULL-SURFACE CENSUS: {n_cells} injectable cells ===")
    # Row 1 (RECOGNITION) is not a census cell at all — it has no injectable
    # body — so it is named here only so the reader knows what this file does
    # NOT count; probe.py owns its number. Every cell here is openlibm's body:
    # CQ ships no C implementation of a library function (bd 3c6m.78).
    #
    # bd keol: `no-body` must be subtracted from the NUMERATOR explicitly. A
    # not-equal-to-"decline" test silently counts every NEW status as COVERED.
    # A cell with no injectable body is neither covered nor declining; it is
    # UNMEASURED. It stays in the DENOMINATOR.
    # ONE predicate, used everywhere "is this cell covered?" is asked. It lives
    # in `probe.py` (bd `5ft3`): importing rather than mirroring is what makes
    # "ONE predicate" true instead of aspirational.
    is_covered = P.is_covered
    icov, ntot = sum(1 for v in results.values() if is_covered(v["status"])), len(results)
    pct  = lambda a, b: f"{round(100*a/b)}%" if b else "n/a"
    print("\nTWO DISJOINT ROWS — never merged:")
    print(f"  1. RECOGNITION  — the hardware keep-set; NOT a cell here (no injectable")
    print(f"                    body). A FIXED FLOOR, never progress. See probe.py.")
    inj_decl = sum(1 for v in results.values() if v["status"] == "decline")
    inj_nb   = sum(1 for v in results.values() if v["status"] == "no-body")
    tail = f"{inj_decl} decline" + (f" + {inj_nb} no-body (NOT probed)" if inj_nb else "")
    print(f"  2. INJECTION    — real upstream openlibm bodies, source-injected:")
    print(f"                    {icov}/{ntot} covered ({pct(icov,ntot)}), "
          f"{tail}.  *** THE CAMPAIGN NUMBER ***")
    print()
    comp = len(buckets.get("COMPILES", []))
    print(f"RAW BUCKET TALLY (all {n_cells} cells): "
          f"plain-COMPILES {comp}, other {n_cells-comp}")
    print("NB `COMPILES` is the plain bucket ONLY — a Phase-6 spec-clone survivor "
          "lands in\n   `COMPILES (spec-clone)` and is covered but NOT in this "
          "tally (bd 3c6m.58).\n")
    print("BY BUCKET (what blocks it):")
    for b, fns in sorted(buckets.items(), key=lambda x: -len(x[1])):
        print(f"  {len(fns):3d}  {b}")
        print(f"       {', '.join(sorted(fns))}")
    # The axis that actually answers "where is the work?" — see SCOPE above.
    scopes = defaultdict(list)
    for k, v in results.items():
        if v["status"] in ("decline", "no-body"):   # bd keol — see check_scope
            scopes[v.get("scope", "UNCLASSIFIED")].append(k)
    print("\nBY SCOPE (is it work?):")
    for s in VALID_SCOPES + ("UNCLASSIFIED",):
        if s in scopes:
            print(f"  {len(scopes[s]):3d}  {s}")
            print(f"       {', '.join(sorted(scopes[s]))}")
    # `n_cells - comp` was WRONG here and had been since the spec-clone bucket
    # existed: `comp` is the PLAIN-COMPILES tally, so it counted every spec-clone
    # survivor as a decline (measured 2026-07-31: it printed "of 26 declines" when
    # there are 20). Use the actual decline count.
    ndecl = sum(1 for v in results.values() if v["status"] == "decline")
    print(f"\nACTIONABLE LEVER GAP: {len(scopes.get('lever-gap', []))} cell(s) "
          f"of {ndecl} declines. Quote THIS, not the decline count.")
    # bd keol — the corpus self-check. A cell reported here was NOT MEASURED, and
    # the distinction matters more than it looks: before this check its probe's
    # unresolved call surfaced as an ordinary "unknown callee" decline, i.e. the
    # census reported an unmeasured cell as a compiler result. Print it as its own
    # banner rather than a bucket row, because the corrective action is to fix the
    # CORPUS (rebuild a .bc, add an alias shim) and not to fix the compiler.
    if missing_entry:
        print(f"\n!! CORPUS GAP — {len(missing_entry)} cell(s) have NO BODY in the "
              f"defmap and were NOT PROBED: {sorted(missing_entry)}")
        print("   These are NOT declines and carry no measured blocker. Rebuild the "
              "corpus (README Reproduce step 1/1b) or add the alias shim, then "
              "re-run; do not scope compiler work against them.")
    check_scope(results)

if __name__ == "__main__":
    main()
