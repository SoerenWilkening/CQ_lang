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
# bd guwr (Rule 18 AMENDMENT, owner 2026-07-31): the CQ-PROVIDED spellings. These
# ARE probed and DO stay in this census — unlike the keep-set, which has no
# injectable body at all — but they are probed against CQ's OWN leaf and are
# reported on their own row. Amendment condition (iii): NEVER merged into the
# injection number. The gate is measured on disk by `probe.cq_provided_cells()`;
# day one that is exactly 6 and it rejects sinf/cosf/tanf (bd `eur4`).
CQPROV = set(P.cq_provided_cells())

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
    # BOTH REFS RE-MEASURED 2026-07-31 (bd guwr) — and both were describing a
    # blocker the pass does not actually hit first. Keep the ruling, fix the
    # evidence: an unverifiable scope_ref is exactly the assertion this table
    # exists to retire.
    "tgammal.f80": ("decided-decline",
                    "RULING STANDS (its own reduction loops ld80/e_tgammal.c:271/277/286, SCEV "
                    "Unpredictable, quantum-governed trip) but that is NOT the measured first "
                    "blocker and was not on the 2026-07-30 baseline either: pre-amendment it "
                    "blocked at `sinl` (unsupported instruction), post-amendment at `stirf` "
                    "(unsupported instruction) — the CQ-provided sinl cleared the sinl layer. "
                    "The loops sit behind stirf and remain UNMEASURED"),
    # RE-SCOPED 2026-08-10 by owner ruling. The previous entry ended "Re-scope
    # before quoting this cell: it may no longer be decided at all" — that
    # re-scope has now happened, and the answer is that the cell stays declined
    # for a NEW and honest reason.
    #
    # THE CHEAP PATH WAS OFFERED AND DECLINED. bd 20xt.8 measured (2026-07-23)
    # that with a branchless `logl` leaf injected this cell returns
    # STATUS=COMPILES, surv:[]; sinl/cosl are already CQ-provided here
    # (cq_linked: [cosl, sinl]), so `logl` was the only remaining variable, and
    # probe._cq_provided_evidence('logl') returns all five condition-(ii)
    # requirements satisfied on disk TODAY. The sole gate was the ruled stem
    # tuple. OWNER RULING 2026-08-10: NOT ADMITTED. Two reasons, both measured:
    #   (a) IT IS NOT +1. `log` and `logl` are BOTH already `COMPILES` by real
    #       openlibm injection, so admitting the stem moves TWO covered cells out
    #       of the injection row to buy ONE — campaign number 97 -> 96. Even a
    #       logl-only admission (which would need the gate changed from per-stem
    #       to per-spelling) is FLAT, not +1. A 2026-08-10 triage round pitched
    #       this as "a measured +1 injection cell ... cheaper than any lever on
    #       the list"; that was wrong on the arithmetic.
    #   (b) THE AMENDMENT'S GROUNDING DOES NOT REACH IT. CQ-PROVIDED exists
    #       because openlibm's SOURCE FORM is un-injectable (trig's Payne-Hanek
    #       k_rem_pio2.c). log's source form works and is injected today, so
    #       admitting it would trade the true claim "CQ compiled openlibm's log"
    #       for the weaker "CQ ships its own log", and leave this cell resting on
    #       THREE CQ leaves.
    #
    # SO WHAT WOULD ACTUALLY MOVE IT is a real capability, and it is NOT bd 5po2
    # alone: measured on the injected body, ld80/e_logl.c at -O1 carries an
    # `alloca i32`, two `store i32` into it and a by-ref `call @frexpl(x86_fp80,
    # ptr)` — the SAME g387/7.5 by-ref out-param axis that owns powl.f80 — plus
    # __isnanl/__polevll/__p1evll/ldexpl, and scanBody recurses into visible
    # nested callees (SpecializeReject.cpp:503-510). Depth behind the control
    # layer is UNMEASURED. Do not scope against a predicted next layer here: this
    # table has mispredicted the next layer three times running on the adjacent
    # gamma pair.
    "lgammal.f80": ("decided-decline",
                    "RE-SCOPED 2026-08-10 (owner ruling). Original ground ('inherited Payne-Hanek "
                    "via sinl') is SPENT — post-amendment sinl is CQ-provided and the measured "
                    "first blocker moved to `logl` (tainted control flow under quantum lift). The "
                    "cheap mover (admit log/logl to CQ-PROVIDED, measured by bd 20xt.8 to flip this "
                    "cell) was OFFERED AND DECLINED: log.f64 and logl.f80 are BOTH already "
                    "injection-COMPILES, so admitting the stem is 97->96 and logl-only is flat, and "
                    "the amendment's grounding (upstream source form un-injectable) does not reach "
                    "a function whose source form works today. Real mover is a capability: in-clone "
                    "control (5po2) AND the g387/7.5 by-ref frexpl axis behind it — depth UNMEASURED"),

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
    "tgammaf.f32":    ("lever-gap",
                       "`large_gam { double, double } (double)`: cq specialization: floating-point "
                       "quantum argument or return has no reversible copy — an AGGREGATE-typed fp "
                       "return under quantum lift. Needs multi-value/struct return support in the "
                       "Phase-6 specializer (or SROA-ing the pair), NOT the fp-range pruning the "
                       "previous ref named"),
    "tgamma.f64":     ("lever-gap",
                       "same single blocker as tgammaf.f32 (tgammaf is (float)tgamma(x)) — both "
                       "advanced together in bd tkmn Inc 1 and again in bd guwr. `large_gam`'s "
                       "{double,double} return is the layer; b_tgamma.c:200's bounded loop and the "
                       "depth-1 self-recursion sit BEHIND it and are still UNMEASURED"),
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

    # -- ilogb x3: FIRST MEASURED 2026-08-10 (bd bcv4 unblocked them; they had
    #    never been probed, so they carried no scope). They are NOT a new ruling
    #    — they are the 2026-07-28 ruling applied to its own stated general form
    #    ("the test is the TRIP COUNT alone" ... "applies to every
    #    data-dependent-trip library body ... and any future one").
    #
    #    The precedent is as direct as it gets: `ilogbl`'s subnormal loop is the
    #    SAME LOOP, character-for-character, as the ADJUDICATED `logbl` cell's,
    #    in the sibling file —
    #        src/s_logbl.c:36   for (b = LDBL_MANH_SIZE; !(u.bits.manl & m); m >>= 1)
    #        src/s_ilogbl.c:37  for (b = LDBL_MANH_SIZE; !(u.bits.manl & m); m >>= 1)
    #    and f64/f32 are the same idiom in their own spelling (shift-until-the-
    #    sign-bit plus a counter):
    #        src/s_ilogb.c:40   for (ix = -1043; lx>0; lx<<=1) ix -=1;
    #        src/s_ilogb.c:42   for (ix = -1022,hx<<=11; hx>0; hx<<=1) ix -=1;
    #        src/s_ilogbf.c:35  for (ix = -126,hx<<=8; hx>0; hx<<=1) ix -=1;
    #    All three: recurrence purely CLASSICAL (a counter + a shift register),
    #    trip count QUANTUM-DEPENDENT (the mantissa is the probe's tainted
    #    input). All three report the identical diagnostic `logbl.f80` reports,
    #    "cq controlled lowering: loop under quantum control".
    #
    #    RE-OPENING CONDITION, stated because it is real and shared with logbl:
    #    each of these loops is BOUNDED by the mantissa width (<=31 / <=23 / <=64
    #    iterations), so a static-K unroll to a branchless fixed-trip kernel — the
    #    `8h7d` widening, and the shape Bennett's 64-iteration restoring divider
    #    already is — WOULD reach them. That is a capability decision, not a
    #    physics wall. If it is ever taken, these 3 cells plus `logbl.f80` are the
    #    population; until then the ruling stands and they are not compiler work.
    **{c: ("decided-decline",
           "owner ruling 2026-07-28 applied per its own general form; ilogbl's loop is character-identical to the adjudicated logbl (src/s_logbl.c:36 == src/s_ilogbl.c:37). Re-opens only via a static-K unroll (8h7d)")
       for c in ("ilogb.f64", "ilogbf.f32", "ilogbl.f80")},
}

def check_scope(results):
    """Rule-12 analog for the scope table: a stale SCOPE is a silent PLANNING
    miscompile, so drift fails loudly instead of being quietly carried forward."""
    # bd keol: a `no-body` cell was never probed, so it is not a DECLINE — but it
    # still carries (and still needs) a SCOPE entry, because "openlibm ships no
    # body for this" is exactly a `corpus-gap` scope. Counting it here keeps the
    # keol classification from reading as SCOPE STALE the moment it starts firing.
    declines = {k for k, v in results.items()
                if v["status"] in ("decline", "no-body")}
    # bd guwr: a CQ-PROVIDED cell stops declining because the pipeline stopped
    # injecting UPSTREAM's body — not because upstream's body became lowerable.
    # Its SCOPE entry (openlibm's k_rem_pio2.c is decided-decline) is therefore
    # still TRUE and is deliberately RETAINED, re-attached to the cell record as
    # `upstream_scope`. Dropping it would erase the only record of why CQ ships
    # its own leaf. So these are exempt from the staleness sweep — and ONLY these.
    cqcells = {k for k, v in results.items() if v.get("provider") == "cq"}
    missing  = sorted(declines - set(SCOPE))
    stale    = sorted(set(SCOPE) - declines - cqcells)
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
    print(f"  CQ-PROVIDED leaves injected: {sorted(WP.cq_provided_shims())} "
          f"(skipped: {WP._CQ_SKIPPED or 'none'})", file=sys.stderr)
    up_defmap = None          # built lazily; only the A/B below needs it
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
            # This is deliberately NOT a hard abort: `nexttowardl.f80` is a
            # KNOWN, owner-recorded corpus gap (openlibm ships no
            # s_nexttowardl.c at all), so the census must still complete and
            # report it. What changes is that it is now classified by the
            # HARNESS, from the corpus, instead of being inferred from a
            # compiler diagnostic that cannot tell the two apart.
            if spelling not in defmap:
                missing_entry.append(key)
                rec = {"status": "no-body", "bucket": "corpus-gap (no body)",
                       "diag": f"{spelling}: no definition in the corpus defmap "
                               f"— NOT PROBED, so this cell has no measured "
                               f"blocker (bd keol)",
                       "provider": "cq" if spelling in CQPROV else "openlibm"}
                if key in SCOPE:
                    rec["scope"], rec["scope_ref"] = SCOPE[key]
                results[key] = rec
                buckets["corpus-gap (no body)"].append(key)
                n_cells += 1
                print(f"  {spelling:12s} {width:4s} CORPUS-GAP (no body — not probed)",
                      file=sys.stderr)
                continue

            linked_cq = []
            st, diag, src = WP.probe(spelling, rw, args, 0, defmap,
                                     deps_out=linked_cq)
            b = bucket(st, diag)
            provider = "cq" if spelling in CQPROV else "openlibm"
            rec = {"status": st, "bucket": b, "diag": diag, "provider": provider}
            if provider == "cq":
                # The upstream ruling stays attached to the cell (see check_scope).
                if key in SCOPE:
                    rec["upstream_scope"], rec["upstream_scope_ref"] = SCOPE[key]
            else:
                if linked_cq:
                    # A/B: LINKED is not RESTS-ON. Re-probe upstream-only and let
                    # the status difference decide (bd guwr).
                    #
                    # `rests_on_cq` means exactly "this cell's COVERAGE depends on
                    # a CQ leaf" — status or bucket changed. It deliberately does
                    # NOT fire when a still-declining cell merely got a DIFFERENT
                    # first blocker: measured 2026-07-31, `tgammal.f80` moved from
                    # blocking at `sinl` to blocking at `stirf`, same bucket, same
                    # decline. That move is real and worth knowing, but it is not a
                    # coverage dependency and folding it in would inflate the audit
                    # list with cells the CQ leaves did not cover. Blocker-only
                    # moves are recoverable by diffing the `diag` field against the
                    # previous census json, which is the comparison every gate runs
                    # anyway — they are not lost, just not labelled here.
                    if up_defmap is None:
                        up_defmap = WP.build_defmap(cq_provided=False)
                    ust, udiag, _ = WP.probe(spelling, rw, args, 0, up_defmap)
                    rec["cq_linked"] = sorted(set(linked_cq))
                    if ust != st or bucket(ust, udiag) != b:
                        rec["rests_on_cq"] = True
                        rec["upstream_status"], rec["upstream_diag"] = ust, udiag
                if st == "decline" and key in SCOPE:
                    rec["scope"], rec["scope_ref"] = SCOPE[key]
            results[key] = rec
            buckets[b].append(key)
            n_cells += 1
            tag = "  [CQ-PROVIDED]" if provider == "cq" else (
                  "  [rests on CQ leaf]" if rec.get("rests_on_cq") else "")
            print(f"  {spelling:12s} {width:4s} {b}{tag}", file=sys.stderr)
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
    # -----------------------------------------------------------------------
    # THREE DISJOINT ROWS — never merged (Rule 18 amendment (iii), owner
    # 2026-07-31; bd `libm-scoreboard-two-numbers` / `guwr`). A single merged
    # headline is the retired 165/174 "95%" overclaim recurring and is a bug.
    # Row 1 (RECOGNITION) is not a census cell at all — it has no injectable
    # body — so it is named here only so the reader knows what this file does
    # NOT count; probe.py owns its number.
    # -----------------------------------------------------------------------
    cq   = {k: v for k, v in results.items() if v.get("provider") == "cq"}
    inj  = {k: v for k, v in results.items() if v.get("provider") != "cq"}
    # bd keol: `no-body` must be subtracted from the NUMERATOR explicitly. A
    # not-equal-to-"decline" test silently counts every NEW status as COVERED,
    # so introducing the keol classification would have moved this row 97 -> 98
    # with no compiler change — the exact soft-overclaim the three-row split and
    # the CONTINUITY line below exist to prevent. A cell with no injectable body
    # is neither covered nor declining; it is UNMEASURED.
    #
    # It stays in the DENOMINATOR, which preserves this row's published meaning
    # bit-for-bit (before keol, `nexttowardl.f80` was a `decline`: in the
    # denominator, out of the numerator). The stricter "can openlibm's body be
    # lowered" denominator that drops it too is one lower, and the README states
    # both.
    # ONE predicate, used everywhere "is this cell covered?" is asked, so the
    # numerator and the A/B audit below cannot drift apart (Rule 14).
    COVERED_EXCL = ("decline", "no-body")
    is_covered = lambda st: st not in COVERED_EXCL
    cov  = lambda d: sum(1 for v in d.values() if is_covered(v["status"]))
    icov, ntot = cov(inj), len(inj)
    ccov, ctot = cov(cq), len(cq)
    pct  = lambda a, b: f"{round(100*a/b)}%" if b else "n/a"
    print("\nTHREE DISJOINT ROWS — never merged (Rule 18 amendment (iii)):")
    print(f"  1. RECOGNITION  — the hardware keep-set; NOT a cell here (no injectable")
    print(f"                    body). A FIXED FLOOR, never progress. See probe.py.")
    # bd keol: split the non-covered remainder. `ntot-icov` used to be printed
    # flatly as "decline", which is now wrong by one and wrong in KIND: a
    # `no-body` cell did not decline, it was never measured. Naming them apart
    # here is the whole point of the keol classification — a reader must not have
    # to know it to avoid scoping compiler work against a missing .bc.
    inj_decl = sum(1 for v in inj.values() if v["status"] == "decline")
    inj_nb   = sum(1 for v in inj.values() if v["status"] == "no-body")
    tail = f"{inj_decl} decline" + (f" + {inj_nb} no-body (NOT probed)" if inj_nb else "")
    print(f"  2. INJECTION    — real upstream openlibm bodies, source-injected:")
    print(f"                    {icov}/{ntot} covered ({pct(icov,ntot)}), "
          f"{tail}.  *** THE CAMPAIGN NUMBER ***")
    print(f"  3. CQ-PROVIDED  — CQ ships the leaf; upstream's body is NOT injected:")
    print(f"                    {ccov}/{ctot} covered ({pct(ccov,ctot)}) — "
          f"{', '.join(sorted(cq)) or 'none'}")
    rej = P.cq_provided_rejected()
    if rej:
        print(f"                    NOT qualified (owner-ruled stem, condition (ii) "
              f"unmet): {', '.join(sorted(rej))}")
    # CONTINUITY — the one way this change could soft-overclaim, stated in the
    # output rather than left for a reader to reconstruct. The CQ-provided cells
    # were ALL declines before the amendment, so moving them out of the injection
    # denominator raises the injection PERCENTAGE with zero compiler work.
    print(f"\n  CONTINUITY: on the pre-amendment denominator (all {n_cells} cells "
          f"counted as injection) this reads {icov}/{n_cells} ({pct(icov,n_cells)}).")
    print(f"  The {ctot} CQ-provided cells were ALL declines before the amendment, so any "
          f"gap between\n  those two percentages is DENOMINATOR, NOT compiler work. "
          f"Quote both or neither.")
    # The audit question the third row exists to keep answerable, split into the
    # two things it could mean — because they carry VERY different weight and
    # printing them as one number reads as an overclaim in whichever direction the
    # reader guesses.
    covdep = sorted(k for k, v in inj.items() if v.get("rests_on_cq")
                    and is_covered(v["status"]) != is_covered(v["upstream_status"]))
    moved  = sorted(k for k, v in inj.items() if v.get("rests_on_cq") and k not in covdep)
    print(f"\n  INJECTION cells whose COVERAGE depends on a CQ-provided leaf "
          f"(A/B-measured, upstream-only re-probe): {len(covdep)}")
    for k in covdep:
        print(f"      {k}: with CQ leaf -> {inj[k]['status'][:38]} | "
              f"upstream-only -> {inj[k]['upstream_status'][:38]}")
    if not covdep:
        print("      NONE. *** The injection numerator above is entirely independent "
              "of the amendment. ***")
    print(f"\n  INJECTION cells that still decline but whose FIRST BLOCKER MOVED: "
          f"{len(moved)}")
    for k in moved:
        print(f"      {k}: {bucket(inj[k]['upstream_status'], inj[k]['upstream_diag'])}"
              f"  ->  {inj[k]['bucket']}")
    print("      (Not coverage — a layer was cleared and the next one is now visible.\n"
          "       A same-BUCKET blocker move is invisible here by construction; recover\n"
          "       those by diffing the `diag` field against the previous census json.)")
    print("      Precedent for depending on a leaf at all: an injected body calling a\n"
          "      hardware keep-set fn already counts as injection-covered — that is why\n"
          "      `ceil` does not block `tgamma`. Listed so the dependency is auditable.")
    print()
    comp = len(buckets.get("COMPILES", []))
    print(f"RAW BUCKET TALLY (all {n_cells} cells, both providers): "
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
    for s in ("lever-gap", "owner-ruling-needed", "deferred-capability",
              "corpus-gap", "decided-decline", "UNCLASSIFIED"):
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
