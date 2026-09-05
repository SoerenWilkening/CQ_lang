#!/usr/bin/env python3
"""golden_multiset_audit.py — the GOLDEN-REGENERATION witness.

TWO MODES, selected by `--epic`:
  * `--epic 2a` (DEFAULT) — bd test_C_libtooling-drbq Inc 2a, the §6a Rz
    control-in-place peephole. Everything from here down to "WHAT IT CANNOT
    WITNESS" describes this mode and is unchanged.
  * `--epic 3qlq` — bd test_C_libtooling-3qlq Increment 1, register-free
    `cq_phi`. See the block comment "--epic 3qlq" further down, and the
    63-golden classification table at the END of this docstring.

bd test_C_libtooling-drbq Inc 2a (the §6a Rz control-in-place peephole),
control-in-place-PRD §9.2 / §12.2(i). Committed as an INSTRUMENT, not as a ctest
gate; read "WHAT IT CANNOT WITNESS" before quoting a green run.

WHY THIS EXISTS. Inc 2a rewrites ~26 committed e2e goldens at once, and PRD §10
names the hazard in one line: "the §9.2 audit is the only thing standing between
'regenerated' and 'regenerated from a broken build'". A golden regenerated from a
compiler that emits the WRONG unitary is perfectly self-consistent — it is a
picture of whatever the compiler did — so the trace byte-diff cannot possibly
catch it. What CAN catch it is a claim about the SHAPE of the change: the only
thing this increment may do to any trace is replace the swap-route quintuple

    cqrt_alloc_<W>(0) -> rail
    cqrt_cswap(f, q, rail)
    cqrt_rz_<W>(rail, theta)          (one or more, all on the same rail)
    cqrt_cswap(f, q, rail)
    cqrt_free(rail)

by one `cqrt_rz_<W>_controlled(f, q, theta)` per rz, with the flag mint, the
`cqrt_x` bracket, the flag strip, the flag free and EVERY OTHER LINE — including
every post-region `_unc` and `cqrt_free` — untouched and in the same order.

FOUR CHECKS PER GOLDEN, ALL ENFORCED (the round-1 review of Inc 2a found (A)
computed-but-never-enforced and no scope check at all — L3 F1/F9):

  (S) SCOPE, asked FIRST and asked of the OLD trace. Inc 2a's scope is the FLAT
      `emitRegion` path; the 4.3 depth-2 nest KEEPS the route. A golden whose OLD
      trace bears a nest signature — a `cqrt_cswap` routing a base that is itself
      a work rail, or two CONTROL flags open at once — must be byte-identical
      old->new, and is reported `OUT-OF-SCOPE` (a failure) if it moved. The
      reducer carries the same fence pointwise: it REFUSES a region whose routed
      base is a work rail, so a collapsed nested inner cannot come out
      `COLLAPSE-ONLY`. Read `out_of_scope_signature`'s docstring for the one case
      this deliberately does NOT catch (the 4.5 switch, which is
      trace-indistinguishable from a sequence of flat regions — measured).

  (A) MULTISET DELTA, the §9.2 form, HANDLE-INVARIANT (`hN` -> `h`, not
      renumber-by-first-appearance: the collapse DELETES a handle-minting line,
      so first-appearance renumbering would bury the arithmetic under noise). The
      observed delta must EQUAL the delta the reducer itself performed — line
      spellings, widths and angles included. It is printed on every audited
      golden, verbose or not, because the numbers PRD §9.2 asks for should be on
      the record whatever the verdict.

  (A2) CSWAP ACCOUNTING. Exactly `2 x n_arms` `cqrt_cswap` lines removed and no
      others moved.

  (B) STRUCTURAL REDUCTION, which is strictly stronger than (A) on ORDER. The OLD
      trace is REDUCED by rewriting every routed REGION into its control-in-place
      form, then both traces are handle-normalised and compared LINE FOR LINE. A
      reordering that leaves the multiset equal (the exact thing bd
      `golden-multiset-diff-audit-2026-08-29` says to look for) still fails here.

`--selftest` runs the audit's own 19-mutant family (L3's, verbatim) plus 4
controls and the out-of-scope probe, against EMBEDDED goldens — no git, no build,
no test tree. Run it after any change to the reducer.

THE `cqrt_x` ARITHMETIC IS PART OF THE EXPECTED SHAPE, NOT AN EXEMPTION. PRD
§9.2 says "the `cqrt_x` brackets … unchanged"; that is true of a NON-negated arm
and FALSE of a negated one, and the difference is structural rather than a
compiler choice. The route brackets EACH of its two `cqrt_cswap`s, so a negated
arm carries FOUR `cqrt_x(f)`; control-in-place brackets the arm's gate run ONCE,
so it carries TWO. The reduction models exactly that (`-2 cqrt_x` per collapsed
negated arm) and the multiset report prints it, so it is visible rather than
waived. Any OTHER `cqrt_x` movement is a failure.

THE ROUTED REGION, as this script matches it (the shape `SwapRouteEmit::emitRegion`
emitted before Inc 2a — allocs batched, route-ins batched, bodies batched,
route-backs batched, frees batched, which is why a per-route contiguous matcher
is NOT enough for an if/else):

    alloc_W(0) -> R_1 ... alloc_W(0) -> R_n          (n = content arms)
    [x(f)] cswap(f,q,R_1) [x(f)] ... [x(f)] cswap(f,q,R_n) [x(f)]
    rz_W(R_1, t) *      ...      rz_W(R_n, t) *
    [x(f)] cswap(f,q,R_1) [x(f)] ... [x(f)] cswap(f,q,R_n) [x(f)]
    free(R_1) ... free(R_n)
  ->
    [x(f)] rz_W_controlled(f,q,t) * [x(f)]   ... per arm, in the same arm order

A region that does NOT match — a 4.3 nested pair, a 4.5 switch, a method-B value
arm, an abort park — is left ALONE by the reducer, which is what lets a golden
that mixes a collapsed flat region with a kept one still pass.

─────────────────────────────────────────────────────────────────────────────────
HOW TO RUN IT (from the repository ROOT)

    python3 tools/golden_multiset_audit.py                # every CHANGED golden
                                                         #   (tracked-modified
                                                         #    AND untracked-new)
    python3 tools/golden_multiset_audit.py --all          # every golden
    python3 tools/golden_multiset_audit.py --selftest     # the mutant validation
    python3 tools/golden_multiset_audit.py tests/e2e/slice_control_phase_diamond.expected.log
    python3 tools/golden_multiset_audit.py --rev HEAD~1   # compare against another rev

Exit code 0 iff every audited golden's diff is exactly the collapse (or empty);
non-zero on any golden that is a `FINDING` or `OUT-OF-SCOPE`. `--verbose` adds the
per-mutant detail in `--selftest` (the (A) delta is printed unconditionally).

─────────────────────────────────────────────────────────────────────────────────
WHAT IT CANNOT WITNESS — read this before quoting a green run

  * IT IS A CLAIM ABOUT THE DIFF, NOT ABOUT THE UNITARY. It proves the new trace
    is the old trace with routes collapsed. If the OLD trace was wrong, the new
    one is wrong in exactly the same way and this script is silent. The old
    stream's correctness is the swap route's own (Phase 4.1, cleared separately).
  * IT CANNOT SEE "FREED AT |0>" — no trace can, at any ABI (bd `8txa`). That is
    stage 2b's job (`tools/free_pairing_check.py`), which runs on the LOWERED IR
    of every slice and must be run as well.
  * A GOLDEN THAT DID NOT CHANGE IS NOT AUDITED by default. `--all` audits every
    golden, but "unchanged" is itself the assertion for those, and `ctest` is what
    checks it. (Since the round-1 review the default set is the union of
    `git diff --name-only` AND `git ls-files --others --exclude-standard`, so a
    brand-new, still-untracked golden is no longer silently skipped — L3 F5.)
  * IT CANNOT DISTINGUISH A 4.5 SWITCH FROM A SEQUENCE OF FLAT REGIONS, so check
    (S) does not cover the switch half of the scope split. That is measured, not
    assumed — see `out_of_scope_signature`. The switch is witnessed by the
    `control_swap_switch_phase*.ll` lit fixtures and by the whole-corpus census
    that no module emits both a `cqrt_cswap` and a `cqrt_rz_*_controlled`.
  * IT READS ONLY THE COMMITTED `.expected.log` FILES. It does not compile
    anything, so it cannot tell you whether the golden matches what the compiler
    emits today — that is the e2e byte-diff.

═════════════════════════════════════════════════════════════════════════════════
`--epic 3qlq` — HOW TO RUN IT, AND WHAT THE 63 GOLDENS LOOK LIKE

    python3 tools/golden_multiset_audit.py --epic 3qlq --selftest   # mutant validation
    python3 tools/golden_multiset_audit.py --epic 3qlq --classify --all
    python3 tools/golden_multiset_audit.py --epic 3qlq --dryrun --all
    python3 tools/golden_multiset_audit.py --epic 3qlq --rev <pre-3qlq-sha>
    python3 tools/golden_multiset_audit_test.py                     # the wider self-test

STATUSES this mode returns: `SUBSTITUTION-ONLY` (the diff is exactly one or more
of (a)-(d)), `AMBIGUOUS-d` / `AMBIGUOUS-ca` (the same, but the golden bears the
class-(d) trace ambiguity and the audit is reporting WHICH reading matched — see
`match_angle_select_pair`), `UNCHANGED` (an OLD trace with no `cqrt_rz`, which is
the assertion for it), `OUT-OF-SCOPE` and `FINDING` (both non-zero exit).

── THE 63-GOLDEN CLASSIFICATION TABLE ──────────────────────────────────────────
MEASURED 2026-09-05 at HEAD `52d7764`, `--epic 3qlq --classify` over
`grep -l cqrt_rz tests/e2e/*.expected.log` (63 files; the tree holds 295 goldens
in total and the other 232 carry no `cqrt_rz` at all and must not move). This is
the map for the regeneration, not a promise about it: it says which substitution
each OLD trace bears, so a NEW golden whose diff is a DIFFERENT class is visible
immediately.

  class            n   goldens
  ───────────────────────────────────────────────────────────────────────────
  (a) only        27   onward_ctl_phase_caller · slice_control_cond_datause ·
                       slice_control_grover_2iter · _derived_oracle{,_2iter,_offset} ·
                       slice_control_grover_loop{,_unrolled,_derived,_derived_unrolled,
                       _dynamic,_leading_gate,_leading_gate_unrolled,_offset,
                       _offset_unrolled,_range_oracle,_range_oracle_unrolled,
                       _two_regs,_two_regs_unrolled} ·
                       slice_control_inplace_ry_loop_grover{,_unrolled} ·
                       slice_control_phase_diamond · slice_control_phase_ifne ·
                       slice_control_seq_grover · slice_control_seq_regions ·
                       slice_control_switch_eqfold ·
                       slice_uncompute_interior_region_derived_cond
  (a) + (c)        1   slice_control_phase_ifelse_derived   (a x3 + c x1)
  (b) flat/switch  1   slice_control_switch_phase           (3 per-case regions)
  (b) NEST         1   slice_control_nested_phase           (⚠ the MODELLED shape)
  (c) only        31   slice_bitint · slice_classical_if_gate ·
                       slice_classical_switch_gate · slice_compare_qq ·
                       slice_control_cond_onward_phase ·
                       slice_control_inplace_ry_loop{,_unrolled,_leading_gate,
                       _leading_gate_unrolled,_leak,_leak_unrolled,_two_regs,
                       _two_regs_unrolled} · slice_ctlz_idiom_loop · slice_f16 ·
                       slice_f80 · slice_fp80_union_unc · slice_funnel_fshl_qq ·
                       slice_intrinsic_{bswap,ctlz,ctpop,fma,fpmath} ·
                       slice_loop_break_qq_phase · slice_loop_iter_local ·
                       slice_loop_phase_accum · slice_select_rail_alias_cond ·
                       slice_uncompute_dead_dag · slice_uncompute_dead_shapes ·
                       spec_select_caller · spec_twoarm_caller
  (d) AMBIGUOUS    2   slice_control_angle_select_rz{,_twin}
  ───────────────────────────────────────────────────────────────────────────
  MIXED is folded into the rows above (only `..._ifelse_derived` mixes classes).
  OUT-OF-SCOPE-for-Inc-1 = the 232 goldens with no `cqrt_rz`; three of them carry
  `cqrt_cswap` and no Rz (`slice_control_abort`, `slice_control_switch_value`,
  `slice_control_value_diamond`) and are Increment 2 / 7.2 territory.

⚠ THREE ROWS OF THAT TABLE COME WITH A WARNING, and they are the interesting ones:

  * the (b)-NEST row is ONE golden and its NEW shape is a MODEL (PRD §3
    "Compound conditions" transcribed onto `SelectMergeEmit`'s `and`-node
    emission), not a measured trace. `match_nest`'s docstring lists the two
    modelling choices; a real trace that disagrees is a question for the owner.
  * the (d) row is TWO goldens and both are trace-AMBIGUOUS with class (c)+(a).
    The audit resolves the ambiguity against the NEW trace and says which reading
    matched; it cannot say the compiler picked the one the SOURCE meant.
  * FIFTEEN of the 31 (c) goldens will legitimately come back as FINDINGS, and
    that is the tool working, not a bug in it. Their slices use
    `(void) cq_phi(x, θ)` as a documented KEEP-ALIVE for a dead tainted chain;
    `cq_phi` loses its register argument under D1, so `clang -O1` deletes that
    whole chain at stage 1 and the diff is far more than a line. MEASURED with
    the PRD §6.1 stand-in — `slice_intrinsic_bswap`'s `llvm.bswap.i32` is gone
    outright. Those fifteen slices need a NEW keep-alive idiom, which is a design
    decision for the owner, not something this audit can adjudicate. See
    `_C_CAVEAT` for the measurement, the list, and why the other sixteen are safe.

── WHAT `--epic 3qlq` CANNOT WITNESS (on top of every 2a limitation above) ─────
  * IT IS DEFINED FROM A PRD, NOT FROM A COMPILER. Increment 1 is DESIGNED, NOT
    IMPLEMENTED at the time this mode was written; nothing in the tree emits a
    `cqrt_rz_i1` kickback. A green `--dryrun` proves the REDUCER, never the pass.
  * IT CANNOT RESOLVE THE CLASS-(d) / CLASS-(c)+(a) AMBIGUITY FROM A TRACE, and
    the two admit different new traces. Adjudicate against the `.c`.
  * IT CANNOT SEE "FREED AT |0>" — the 2a limitation is unchanged and stage 2b
    (`tools/free_pairing_check.py`) still owns it. In particular the conjunction
    ancilla `g` of a compound condition is a rail this tool only counts.
  * IT SAYS NOTHING ABOUT THE UNITARY. The whole POINT of Increment 1 is that the
    OLD traces were the identity on `q` (PRD §1); proving a diff is the admitted
    substitution does not prove the NEW unitary is the oracle. That claim belongs
    to the Rule-13 lenses (PRD §10.3), not here.
"""

import argparse
import collections
import os
import re
import subprocess
import sys

CALL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\((.*?)\)(?: -> (.*))?$")
HANDLE = re.compile(r"\bh(\d+)\b")
ALLOC = re.compile(r"cqrt_alloc_(\w+)")
RZ = re.compile(r"cqrt_rz_(\w+)")


def parse(line):
    """-> (callee, [args], ret) or None for a line that is not a trace call."""
    m = CALL.match(line.strip())
    if not m:
        return None
    args = [x.strip() for x in m.group(2).split(",")] if m.group(2) else []
    return m.group(1), args, m.group(3)


def normalise(lines):
    """Renumber handles by FIRST APPEARANCE.

    Mandatory, not cosmetic: the routed trace mints one extra `cqrt_alloc` per
    arm, so every later handle number shifts by a constant that is not a defect.
    A real REORDERING still shows up, because the numbering follows first
    appearance in the (already reduced) sequence.
    """
    m, out = {}, []
    for line in lines:
        def sub(x):
            k = x.group(1)
            if k not in m:
                m[k] = str(len(m))
            return "h" + m[k]
        out.append(HANDLE.sub(sub, line))
    return out


def _route_leg(P, i, rail, flag, base):
    """Match one route leg at `i`: `[x(f)] cswap(f, base, rail) [x(f)]`.

    -> (next_index, negated) or None. The bracket must be the SAME flag on both
    sides; a lone `cqrt_x` is not a bracket and does not match.
    """
    neg = False
    j = i
    if j < len(P) and P[j] and P[j][0] == "cqrt_x" and P[j][1] == [flag]:
        neg = True
        j += 1
    if j >= len(P) or not P[j] or P[j][0] != "cqrt_cswap":
        return None
    if P[j][1] != [flag, base, rail]:
        return None
    j += 1
    if neg:
        if j >= len(P) or not P[j] or P[j][0] != "cqrt_x" or P[j][1] != [flag]:
            return None
        j += 1
    return j, neg


def work_rails(P):
    """Every handle that is routed INTO by some `cqrt_cswap` (its arg 2).

    This is the WORK-RAIL set, and it is deliberately not "every
    `cqrt_alloc_<W>(0)`": a register whose source value happens to be 0 allocates
    the same way (`slice_control_seq_grover`'s `cqrt_alloc_i32(0) -> h0` IS the
    register), so keying on the alloc literal would refuse a legitimate flat
    region. A rail is what a route SWAPS INTO.
    """
    return {p[1][2] for p in P
            if p and p[0] == "cqrt_cswap" and len(p[1]) == 3}


def match_route_region(P, i, rails_set=None, expect_flag=None, expect_base=None):
    """Match a whole ROUTED PHASE REGION starting at trace index `i`.

    -> (next_index, flag, base, arms) or None, where `arms` is a list of
    (width, rail, [theta, …], negated) in EMISSION order.

    This is the ONE matcher (Rule 14). Two emitters sit on top of it:
    `match_region` (the Inc-2a `cqrt_rz_<W>_controlled` collapse) and, under
    `--epic 3qlq`, `_emit_kickback_arms` (the register-free `cqrt_rz_i1` form).
    Everything is matched POSITIONALLY against the pre-2a `emitRegion` emission
    order; any deviation returns None and the caller copies the line through
    unchanged.

    `expect_flag` / `expect_base`, when given, PIN the region's flag and routed
    base instead of reading them off the first `cqrt_cswap`. They are used by
    `match_nest` for the INNER level of a 4.3 depth-2 nest, whose flag and base
    the caller has already read from the mint it consumed.

    SCOPE FENCE (bd drbq Inc 2a round-1 review, L3 F1): a region whose ROUTED
    BASE is itself a work rail belongs to an ENCLOSING route — that is exactly
    what a 4.3 depth-2 nest's INNER region looks like — and Inc 2a does NOT
    collapse it. Refusing to reduce it here means a golden in which a nested
    inner region HAD collapsed cannot come out `COLLAPSE-ONLY`: the reduced old
    still carries the route and the comparison fails loudly. Measured on the
    unchanged `slice_control_nested_phase` golden: the matcher's one hit there is
    the INNER region (base `h2`, the outer route's rail) and this fence refuses
    it, taking `regions_matched` from 1 to 0. `--epic 3qlq` DOES rewrite that
    inner region, and reaches it through `match_nest` (which pins the base) —
    never by relaxing this fence.
    """
    # (1) the batched |0> work-rail allocs.
    rails, widths = [], []
    j = i
    while j < len(P) and P[j] and ALLOC.fullmatch(P[j][0] or "") \
            and P[j][1] in (["0"], ["0x0p+0"]) and P[j][2]:
        rails.append(P[j][2])
        widths.append(ALLOC.fullmatch(P[j][0]).group(1))
        j += 1
    if not rails:
        return None

    # (2) the batched route-ins. The flag and the routed base come from the FIRST
    #     cswap and every later leg must agree — a region routes ONE base under
    #     ONE flag (`emitRegion`'s `RestoringRoutes` convention).
    k = j
    if k < len(P) and P[k] and P[k][0] == "cqrt_x":
        k += 1
    if k >= len(P) or not P[k] or P[k][0] != "cqrt_cswap" or len(P[k][1]) != 3:
        return None
    flag, base = P[k][1][0], P[k][1][1]
    if P[k][1][2] != rails[0]:
        return None
    if expect_flag is not None and flag != expect_flag:
        return None
    if expect_base is not None and base != expect_base:
        return None
    if rails_set is not None and base in rails_set:
        return None  # SCOPE: an inner region of an enclosing route (4.3 nest).
    negated = []
    for r in rails:
        leg = _route_leg(P, j, r, flag, base)
        if leg is None:
            return None
        j, neg = leg
        negated.append(neg)

    # (3) the batched arm bodies: rz on rail 1, then rail 2, … Zero gates on a
    #     rail cannot happen (a gate-free arm was never routed) and is refused.
    bodies = [[] for _ in rails]
    for idx, r in enumerate(rails):
        while j < len(P) and P[j] and RZ.fullmatch(P[j][0] or "") \
                and len(P[j][1]) == 2 and P[j][1][0] == r:
            if RZ.fullmatch(P[j][0]).group(1) != widths[idx]:
                return None
            bodies[idx].append(P[j][1][1])
            j += 1
        if not bodies[idx]:
            return None

    # (4) the batched route-backs — same legs, same order, same polarity.
    for idx, r in enumerate(rails):
        leg = _route_leg(P, j, r, flag, base)
        if leg is None or leg[1] != negated[idx]:
            return None
        j = leg[0]

    # (5) the batched rail frees.
    for r in rails:
        if j >= len(P) or not P[j] or P[j][0] != "cqrt_free" or P[j][1] != [r]:
            return None
        j += 1

    arms = [(widths[x], rails[x], bodies[x], negated[x])
            for x in range(len(rails))]
    return j, flag, base, arms


def match_region(P, i, rails_set=None):
    """The Inc-2a EMITTER over `match_route_region`.

    Returns (next_index, replacement_lines, n_arms, n_gates, n_negated) or None —
    the routed quintuple rewritten as one `cqrt_rz_<W>_controlled(f, q, theta)`
    per rz, with the `cqrt_x` bracket collapsed from four to two per negated arm.
    """
    m = match_route_region(P, i, rails_set)
    if not m:
        return None
    j, flag, base, arms = m
    out, gates = [], 0
    for (w, _rail, thetas, neg) in arms:
        if neg:
            out.append("cqrt_x(%s)" % flag)
        for t in thetas:
            out.append("cqrt_rz_%s_controlled(%s, %s, %s)" % (w, flag, base, t))
            gates += 1
        if neg:
            out.append("cqrt_x(%s)" % flag)
    return j, out, len(arms), gates, sum(1 for a in arms if a[3])


def reduce_routes(lines):
    """Rewrite every routed PHASE region into its control-in-place form.

    -> (reduced_lines, n_regions, n_arms, n_gates, n_negated_arms). A region the
    matcher does not recognize — a 4.3 nest's inner region, a 4.5 switch arm that
    is not a flat region, a method-B value arm — is copied through verbatim, which
    is what lets a mixed golden pass.
    """
    P = [parse(l) for l in lines]
    RS = work_rails(P)
    out, i, nreg, narm, ngate, nneg = [], 0, 0, 0, 0, 0
    while i < len(lines):
        m = match_region(P, i, RS)
        if m:
            j, repl, a, g, ng = m
            out += repl
            nreg += 1
            narm += a
            ngate += g
            nneg += ng
            i = j
            continue
        out.append(lines[i])
        i += 1
    return out, nreg, narm, ngate, nneg


# ─────────────────────────────────────────────────────────────────────────────
# SCOPE (bd drbq Inc 2a round-1 review, L3 F1) — "did the collapse stay inside
# the FLAT path?", asked of the OLD trace.
# ─────────────────────────────────────────────────────────────────────────────

FLAGMINT = re.compile(r"cq_template_(icmp|fcmp)_[A-Za-z0-9_]+$")


def _is_flag_mint(p):
    return bool(p and p[2] and FLAGMINT.fullmatch(p[0] or "")
                and not p[0].endswith("_unc") and not p[0].endswith("_inv"))


def _is_flag_strip(p):
    return bool(p and (p[0] or "").startswith("cq_template_")
                and ((p[0].endswith("_unc") or p[0].endswith("_inv")))
                and re.match(r"cq_template_(icmp|fcmp)_", p[0]) and p[1])


def out_of_scope_signature(lines):
    """-> a reason string if this trace bears a NESTED or SWITCH signature, else None.

    Inc 2a's scope is the FLAT `emitRegion` path; the 4.3 depth-2 nest and the 4.5
    switch KEEP the route. A golden bearing one of those signatures must therefore
    be byte-identical old->new, and `audit()` fails it loudly if it is not.

    (S1) NESTED — a `cqrt_cswap` whose ROUTED BASE is itself a work rail. That is
         the depth-2 nest's inner level and nothing else in the emitted vocabulary
         produces it. Fires on `slice_control_nested_phase`; does NOT fire on
         `slice_control_seq_grover` / `slice_control_seq_regions`, whose bases are
         registers.

    (S2) TWO **CONTROL** FLAGS OPEN AT ONCE — a second flag minted while an
         earlier one is still unstripped, where BOTH are used as a control (arg 0
         of a `cqrt_cswap` or of a `cqrt_r{y,z}_*_controlled`). That is a nest's
         flag-per-level. The "control" restriction is load-bearing and was
         MEASURED: without it the check fired on 30+ unrelated goldens whose
         DERIVED-condition chains legitimately keep two `cq_template_icmp_*`
         results live at once, which would have turned every future edit to one
         of them into a spurious OUT-OF-SCOPE failure.

    ⚠ WHAT THIS DOES **NOT** CATCH, stated because a scope check nobody has
    measured the limits of is worse than none. A 4.5 SWITCH's phase trace is
    structurally INDISTINGUISHABLE from a sequence of flat regions at the trace
    level — measured: `slice_control_switch_phase` (three `icmp_eq` mint / route /
    strip groups on one base, nothing between them) has the same shape as
    `slice_control_seq_regions` (two `icmp_sgt` groups on one base, nothing
    between them), and the second IS in scope and DOES collapse. There is no
    sound trace-only discriminator, so a hypothetical switch collapse would still
    read as `COLLAPSE-ONLY` here. The switch half of the scope split is witnessed
    ELSEWHERE — by the `control_swap_switch_phase*.ll` lit fixtures (which assert
    `cqrt_cswap` positively) and by the whole-corpus census that no module emits
    both a `cqrt_cswap` and a `cqrt_rz_*_controlled`. Do not quote a green run
    here as evidence for it.
    """
    P = [parse(l) for l in lines]
    RS = work_rails(P)
    for p in P:
        if p and p[0] == "cqrt_cswap" and len(p[1]) == 3 and p[1][1] in RS:
            return "nested route: cswap routes base %s, itself a work rail" % p[1][1]
    ctl = set()
    for p in P:
        if not p or not p[1]:
            continue
        n = p[0] or ""
        if n == "cqrt_cswap" or (n.startswith("cqrt_r") and n.endswith("_controlled")):
            ctl.add(p[1][0])
    open_flags = []
    for p in P:
        if _is_flag_mint(p):
            if p[2] in ctl:
                open_flags.append(p[2])
            if len(open_flags) > 1:
                return ("two control flags open at once (%s), a per-level nest "
                        "signature" % ", ".join(open_flags))
        elif _is_flag_strip(p) and p[1] and p[1][0] in open_flags:
            open_flags.remove(p[1][0])
    return None


def strip_handles(lines):
    """Handle-INVARIANT normalisation: every `hN` -> `h`.

    Used only by check (A). Unlike `normalise` (renumber by first appearance) this
    survives the removal of a line that mints a handle, which is exactly what the
    collapse does — so the (A) multiset delta comes out as the collapse arithmetic
    itself rather than as renumbering noise.
    """
    return [HANDLE.sub("h", l) for l in lines]


def expected_delta(old_lines, narm, ngate, nneg):
    """The §9.2 multiset delta the collapse MUST produce, handle-stripped.

    -> (Counter_only_old, Counter_only_new), built from the OLD trace's own
    removed lines so the widths and angles are the real ones rather than a guess.
    """
    P = [parse(l) for l in old_lines]
    RS = work_rails(P)
    only_old, only_new = collections.Counter(), collections.Counter()
    i = 0
    while i < len(old_lines):
        m = match_region(P, i, RS)
        if not m:
            i += 1
            continue
        j, repl, _a, _g, _n = m
        for l in strip_handles(old_lines[i:j]):
            only_old[l] += 1
        for l in strip_handles(repl):
            only_new[l] += 1
        i = j
    common = only_old & only_new
    return only_old - common, only_new - common


# ═════════════════════════════════════════════════════════════════════════════
# --epic 3qlq — REGISTER-FREE `cq_phi` (bd test_C_libtooling-3qlq Increment 1,
# `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §10.2).
#
# The four ADMITTED substitutions, each applied PER REGION, and nothing else:
#
#  (a) FLAT 2a line.   `cqrt_rz_<W>_controlled(f, h, θ)` -> `cqrt_rz_i1(f, θ)`.
#      Same f, same θ; `h` disappears from that line. The `cqrt_x(f)` bracket,
#      the flag mint, the `_unc` strip and the `cqrt_free(f)` are UNCHANGED.
#
#  (b) ROUTED quintuple.
#          cqrt_alloc_<W>(0) -> w ; [x(f)] cqrt_cswap(f,q,w) [x(f)]
#          cqrt_rz_<W>(w, θ)+
#          [x(f)] cqrt_cswap(f,q,w) [x(f)] ; cqrt_free(w)
#      -> the ONE line `cqrt_rz_i1(f, θ)` per θ, `cqrt_x(f)`-bracketed ONCE for a
#      negated arm (four brackets become two, exactly as in the 2a collapse).
#      The 4.5 SWITCH is N independent flat regions of this shape (measured:
#      `slice_control_switch_phase` is three mint/route/strip groups on one base),
#      so N cases give N per-case flags each with its own `rz_i1` for free.
#      The 4.3 depth-2 NEST is `match_nest` — see its docstring.
#
#  (c) UNCONTROLLED `cqrt_rz_<W>(h, θ)` line DELETED, no other change (owner
#      decision D2: an uncontrolled / classically-controlled `cq_phi` is a global
#      phase). ⚠ READ `_C_CAVEAT` BELOW BEFORE QUOTING THIS AS "just a deletion".
#
#  (d) the drbq Inc-2b BY-DIFFERENCE pair
#          cqrt_rz_<W>(h, B) ; <flag mint> ; cqrt_rz_<W>_controlled(f, h, A−B)
#      -> the exact two-gate form
#          <flag mint> ; cqrt_x(f) ; cqrt_rz_i1(f, B) ; cqrt_x(f) ; cqrt_rz_i1(f, A)
#      (PRD §3 "Angle select": `P(A)` on f=1, `P(B)` on f=0, exact, no
#      subtraction). A is RECOVERED from the OLD trace as `fl(B + D)` and is
#      therefore checked with a TOLERANCE — see `a_tolerance`.
#
# Anything else — a moved `_unc`, a changed free order, a handle that stops being
# freed, an extra or missing gate, an Ry line that changed — is a FINDING and the
# exit code is non-zero. Handle RENUMBERING is the only tolerated drift.
#
# ─────────────────────────────────────────────────────────────────────────────
# ⚠ DEFINED FROM THE PRD, NOT MEASURED. Increment 1 is DESIGNED, NOT IMPLEMENTED
# at the time this mode was written (bd `test_C_libtooling-3qlq`, 2026-09-05): no
# compiler in the tree emits a `cqrt_rz_i1` kickback, so every NEW-side shape
# above is READ OFF PRD §3 and §10.2 rather than off a trace. The (b)-NEST
# conjunction shape in particular — `cqrt_alloc_i1(0) -> g`,
# `cqrt_toffoli(f_a, f_b, g)`, `cqrt_rz_i1(g, θ)`, toffoli undo, `cqrt_free(g)`,
# then the per-leaf strips in reverse mint order — is the PRD's
# "Compound conditions" paragraph transcribed onto the node shape
# `SelectMergeEmit.cpp:140-292` already emits for an `and` node (verified against
# `tests/e2e/slice_control_select_compound.expected.log`). When the implementer's
# first real trace exists, DIFF IT AGAINST THIS MODEL AND FIX WHICHEVER IS WRONG;
# a mismatch here is a question for the owner, not automatically a compiler bug.
# The (a), (c) and (d) shapes are far less speculative — they are line-local — but
# they are unmeasured too.
# ─────────────────────────────────────────────────────────────────────────────
#
# _C_CAVEAT — WHERE CLASS (c) IS **NOT** A PURE LINE DELETION, AND IT IS 15 OF THE
# 31 (c) GOLDENS, NOT AN EDGE CASE.
#
# `cq_phi` loses its register argument (owner decision D1 / PRD §4.1). Fifteen of
# the slices behind the 63 goldens use `(void) cq_phi(x, θ)` as a DOCUMENTED
# KEEP-ALIVE — the device that stops `clang -O1` deleting the dead tainted chain
# the slice exists to exercise. `slice_intrinsic_bswap.c` says so in as many
# words: "Rz keep-alive; result dropped", and `slice_uncompute_dead_dag.c`'s
# header calls `cq_phi` "a side-effecting extern that READS its operand". Under
# D1 it reads nothing, and the device is gone.
#
# MEASURED (2026-09-05, the PRD §6.1 `void cq_phase(double)` stand-in method,
# `clang -O1`): with today's `cq_phi` the chain survives —
#     %2 = call i32 @cq_theta_si32(i32 %0, double 1.0e-01)
#     %3 = call i32 @llvm.bswap.i32(i32 %2)
#     call void @cq_phi_si32_old(i32 %3, double 3.0e-01)
# and with D1's register-free spelling the `llvm.bswap.i32` IS DELETED OUTRIGHT:
#     %2 = call i32 @cq_theta_si32(i32 %0, double 1.0e-01)
#     call void @cq_phase(double 3.0e-01)
# So `slice_intrinsic_bswap`'s golden does not lose ONE line, it loses the
# template call, both `cqrt_rz` lines, the `_unc` twin and the `cqrt_free` — the
# whole subject of the test. This mode reports those goldens as FINDINGS **by
# design**; the finding is the flag that says the SLICE needs a new keep-alive,
# which is a design decision and not something an audit can adjudicate.
#
# The fifteen (all in the (c)-only row of the table in this file's docstring):
#   slice_bitint · slice_compare_qq · slice_ctlz_idiom_loop · slice_f16 ·
#   slice_f80 · slice_fp80_union_unc · slice_funnel_fshl_qq ·
#   slice_intrinsic_{bswap,ctlz,ctpop,fma,fpmath} · slice_loop_iter_local ·
#   slice_uncompute_dead_dag · slice_uncompute_dead_shapes
# The other SIXTEEN (c) goldens are safe: measured, every one writes
# `v = cq_phi(v, θ)` with `v` live downstream, so deleting the Rz really is a
# pure line deletion.
#
# Note also that the Rz ADJOINT is spelled as a negated-angle FORWARD call
# (`cqrt_rz_i32(h1, -0x1p-1)` — measured; `grep 'cqrt_rz[a-z0-9_]*_inv'` over every
# golden returns nothing), so a (c) deletion on an uncomputed register deletes a
# PAIR of lines. `(C)` in the report counts forward/adjoint pairs separately.
# ═════════════════════════════════════════════════════════════════════════════

_ABI_W = "i1|i8|i16|i32|i64|f16|f32|f64|f80"
RZ_UNC = re.compile(r"cqrt_rz_(%s)$" % _ABI_W)
RZ_CTL = re.compile(r"cqrt_rz_(%s)_controlled$" % _ABI_W)
RY_ANY = re.compile(r"cqrt_ry_[A-Za-z0-9_]+$")

# The class-(d) recovered-A placeholder. It is substituted by `reconcile_angles`
# with the NEW trace's OWN angle text once the IEEE tolerance check has passed,
# so no Python-formatted float ever reaches the structural comparison.
_A_TOKEN = "@A@"

# ── the class-(d) tolerance, and why it cannot be an equality ────────────────
# The OLD trace carries `D = fl(A − B)`, so A is recoverable only as
# `A_rec = fl(B + D)`. With round-to-nearest `|fl(x) − x| <= u|x|`, `u = 2^-53`:
#     |A_rec − A|  <=  u|D| + u|A| + O(u^2)
# The shipped tolerance is TWICE that first-order bound,
#     tol = 2^-52 · (|A| + |D|)  +  2^-1074
# (the absolute floor is one subnormal, so an exactly-zero A is comparable and a
# subnormal A is not compared against a zero tolerance).
# MEASURED, and this is why the check exists at all: on the committed
# `slice_control_angle_select_rz` golden B = 0x1.3333333333333p-2 and
# D = 0x1.3333333333334p-1, so `fl(B + D)` = 0x1.ccccccccccccep-1 while the true
# source angle is A = 0.9 = 0x1.ccccccccccccdp-1 — ONE ULP APART. An `==` here
# would fail the flagship golden. `1.11e-16` observed against `3.33e-16` allowed.
# The tolerance is deliberately NOT widened beyond ~2 ulp: the drbq Inc-2b
# clearance (blocker F-11) showed the by-difference error is unbounded in
# ABSOLUTE radians for run-time arms, so a loose tolerance here would stop
# discriminating exactly where 2b was wrong.
A_TOL_REL = 2.0 ** -52
A_TOL_ABS = 5e-324  # one subnormal


def a_tolerance(a_new, d):
    return A_TOL_REL * (abs(a_new) + abs(d)) + A_TOL_ABS


def _cfmt(x):
    """A double as C's `%a` prints it (which is what the runtime emits).

    Python's `float.hex()` pads the mantissa to 13 hex digits; C trims trailing
    zeros and drops a then-empty '.'. Verified against the committed goldens:
    0.5 -> `0x1p-1`, 0.75 -> `0x1.8p-1`, 0.9 -> `0x1.ccccccccccccdp-1`,
    0.0 -> `0x0p+0`, -0.3 -> `-0x1.3333333333333p-2`.
    """
    h = float.hex(x)
    if "p" not in h:
        return h  # inf / nan
    m, e = h.split("p")
    if "." in m:
        m = m.rstrip("0").rstrip(".")
    return m + "p" + e


def _sub_handle(line, frm, to):
    """Replace the WHOLE handle token `frm` by `to`. `\\b` keeps `h2` out of `h20`."""
    return re.sub(r"\b%s\b" % re.escape(frm), to, line)


def _handle_gen(lines):
    """A source of handle names that cannot collide with any in `lines`."""
    used = {int(m) for l in lines for m in HANDLE.findall(l)}
    box = [max(used) + 1 if used else 0]

    def nxt():
        box[0] += 1
        return "h%d" % (box[0] - 1)
    return nxt


def _emit_kickback_arms(flag, arms, out, cnt, key):
    """(b) — the routed arms of ONE region as register-free kickback gates."""
    for (_w, _rail, thetas, neg) in arms:
        if neg:
            out.append("cqrt_x(%s)" % flag)
        for t in thetas:
            out.append("cqrt_rz_i1(%s, %s)" % (flag, t))
            cnt[key] += 1
        if neg:
            out.append("cqrt_x(%s)" % flag)


def match_nest(P, lines, i, RS, hgen):
    """(b)-NEST — the 4.3 depth-2 homogeneous PHASE nest, starting at the OUTER
    `cqrt_alloc_<W>(0)` at index `i`.

    -> (next_index, replacement_lines, n_outer_gates, n_inner_gates) or None.

    OLD (measured, `tests/e2e/slice_control_nested_phase.expected.log`; the outer
    mint and strip sit OUTSIDE this span and are not touched):

        cqrt_alloc_<W>(0) -> w1
        [x(fa)] cqrt_cswap(fa, q, w1) [x(fa)]
        cqrt_rz_<W>(w1, θo)*                       outer arm gates
        <mint fb ON w1>                            the inner compare reads the RAIL
        cqrt_alloc_<W>(0) -> w2
        [x(fb)] cqrt_cswap(fb, w1, w2) [x(fb)]
        cqrt_rz_<W>(w2, θi)+
        [x(fb)] cqrt_cswap(fb, w1, w2) [x(fb)]
        cqrt_free(w2)
        <strip fb ON w1> ; cqrt_free(fb)
        [x(fa)] cqrt_cswap(fa, q, w1) [x(fa)]
        cqrt_free(w1)

    NEW — ⚠ DEFINED FROM PRD §3 "Compound conditions", NOT MEASURED:

        cqrt_rz_i1(fa, θo)*                        [x(fa)]-bracketed if negated
        <mint fb ON q>                             the RAIL IS GONE: w1 -> q
        cqrt_alloc_i1(0) -> g
        [x(fb)] cqrt_toffoli(fa, fb, g) [x(fb)]    g = fa ∧ fb
        cqrt_rz_i1(g, θi)+
        [x(fb)] cqrt_toffoli(fa, fb, g) [x(fb)]    LIFO undo, toffoli FIRST
        cqrt_free(g)
        <strip fb ON q> ; cqrt_free(fb)

    Two things here are MODELLING CHOICES rather than transcription, and a real
    trace that disagrees with either is a question, not a bug:
      * the inner mint/strip have their quantum operand rewritten `w1 -> q`. That
        is forced, not optional — under the new scheme nothing routes q onto a
        rail, so there IS no w1 for the compare to read. Semantically the inner
        leaf flag becomes `b(q)` computed unconditionally instead of `b(0 or q)`,
        and the conjunction `fa ∧ fb` makes the GATE identical either way.
      * a NEGATED leg brackets the toffoli PAIR with `cqrt_x` on the leaf flag,
        mirroring how the route bracketed its cswap pair. PRD §3 does not spell
        this case out. Both nest goldens in the tree are non-negated, so this
        clause is exercised only by the selftest.

    Deliberately REFUSED (returns None, the caller copies the region through and
    the audit reports a FINDING): more than one outer arm; an outer gate AFTER
    the inner region; a depth-3 nest; two inner regions under one outer arm.
    """
    if not (i < len(P) and P[i] and ALLOC.fullmatch(P[i][0] or "")
            and P[i][1] in (["0"], ["0x0p+0"]) and P[i][2]):
        return None
    w1 = P[i][2]
    j = i + 1
    k = j
    if k < len(P) and P[k] and P[k][0] == "cqrt_x":
        k += 1
    if k >= len(P) or not P[k] or P[k][0] != "cqrt_cswap" or len(P[k][1]) != 3:
        return None
    fa, base = P[k][1][0], P[k][1][1]
    if P[k][1][2] != w1 or base in RS:
        return None  # `base in RS` => THIS is an inner level; its outer owns it.
    leg = _route_leg(P, j, w1, fa, base)
    if leg is None:
        return None
    j, neg_a = leg

    outer = []
    while j < len(P) and P[j] and RZ_UNC.fullmatch(P[j][0] or "") \
            and len(P[j][1]) == 2 and P[j][1][0] == w1:
        outer.append(P[j][1][1])
        j += 1

    if j >= len(P) or not _is_flag_mint(P[j]) or w1 not in P[j][1]:
        return None
    fb = P[j][2]
    mint_b = _sub_handle(lines[j], w1, base)
    j += 1

    inner = match_route_region(P, j, None, expect_flag=fb, expect_base=w1)
    if inner is None:
        return None
    j, _f, _b, arms = inner
    if len(arms) != 1:
        return None
    _wi, _ri, thetas_i, neg_b = arms[0]

    if j >= len(P) or not _is_flag_strip(P[j]) or P[j][1][0] != fb:
        return None
    strip_b = _sub_handle(lines[j], w1, base)
    j += 1
    if j >= len(P) or not P[j] or P[j][0] != "cqrt_free" or P[j][1] != [fb]:
        return None
    free_b = lines[j]
    j += 1

    leg = _route_leg(P, j, w1, fa, base)
    if leg is None or leg[1] != neg_a:
        return None
    j = leg[0]
    if j >= len(P) or not P[j] or P[j][0] != "cqrt_free" or P[j][1] != [w1]:
        return None
    j += 1

    g = hgen()
    out = []
    if outer and neg_a:
        out.append("cqrt_x(%s)" % fa)
    for t in outer:
        out.append("cqrt_rz_i1(%s, %s)" % (fa, t))
    if outer and neg_a:
        out.append("cqrt_x(%s)" % fa)
    out.append(mint_b)
    out.append("cqrt_alloc_i1(0) -> %s" % g)
    for _pass in range(2):          # forward, then the LIFO undo (self-inverse)
        if neg_b:
            out.append("cqrt_x(%s)" % fb)
        out.append("cqrt_toffoli(%s, %s, %s)" % (fa, fb, g))
        if neg_b:
            out.append("cqrt_x(%s)" % fb)
        if _pass == 0:
            for t in thetas_i:
                out.append("cqrt_rz_i1(%s, %s)" % (g, t))
    out.append("cqrt_free(%s)" % g)
    out.append(strip_b)
    out.append(free_b)
    return j, out, len(outer), len(thetas_i)


def match_angle_select_pair(P, lines, i):
    """(d) — the drbq Inc-2b BY-DIFFERENCE pair at index `i`.

    -> (next_index, replacement_lines, a_rec, B, D) or None.

    The five clauses, ALL required, and each one is here because something in the
    tree would otherwise be mis-substituted:
      1. line `i` is an UNCONTROLLED `cqrt_rz_<W>(h, B)`;
      2. line `i+1` is a flag mint `-> f`  (`AngleSelectEmit` emits the classical
         difference — which prints nothing — then the unconditional twin, then the
         mint, so the mint really is the very next TRACE line);
      3. line `i+2` is `cqrt_rz_<W>_controlled(f, h, D)`, SAME width, SAME h;
      4. line `i+3` is f's strip — i.e. the region body is EXACTLY that one gate,
         with no `cqrt_x` bracket and no second gate;
      5. B and D parse as hex floats.

    Clause 4 is the one that MATTERS and it was written against a measured
    counter-example: `slice_control_phase_ifelse_derived` satisfies clauses 1-3
    (an unconditional pre-region `cqrt_rz_i32(h0, 0x1.ccc…p-1)` sitting
    immediately before the mint, then controlled gates on h0) and is NOT a 2b
    pair — it is class (c) + three of class (a), including an `cqrt_x`-bracketed
    else arm. Without clause 4 the reducer would invent an angle select there.

    ⚠ RESIDUAL AMBIGUITY, STATED BECAUSE IT CANNOT BE CLOSED FROM A TRACE.
    `q = cq_phi(q, B); if (q > 5) q = cq_phi(q, D);` — an ordinary class (c)
    followed by a single-gate class (a) on the same register — emits a trace that
    is CHARACTER-FOR-CHARACTER what a 2b angle select emits, and the two admit
    DIFFERENT new traces (one `rz_i1`, versus four lines). `audit_pair_3qlq`
    therefore reduces TWICE — once with (d) enabled and once with it disabled —
    and reports WHICH variant the new trace matched, as `AMBIGUOUS-d` /
    `AMBIGUOUS-ca`. Resolution is unique given a new trace (the two candidates
    differ in line count), but the audit CANNOT tell you the compiler picked the
    variant the SOURCE meant: check the `.c`. MEASURED over the 63 goldens
    (`--epic 3qlq --classify`): exactly TWO bear this signature,
    `slice_control_angle_select_rz` and `slice_control_angle_select_rz_twin`, and
    both are genuine 2b angle selects by their sources.
    """
    p = P[i]
    if not (p and RZ_UNC.fullmatch(p[0] or "") and len(p[1]) == 2):
        return None
    W = RZ_UNC.fullmatch(p[0]).group(1)
    h, btxt = p[1][0], p[1][1]
    if i + 3 >= len(P):
        return None
    if not _is_flag_mint(P[i + 1]):
        return None
    f = P[i + 1][2]
    q = P[i + 2]
    if not (q and RZ_CTL.fullmatch(q[0] or "") and len(q[1]) == 3):
        return None
    if RZ_CTL.fullmatch(q[0]).group(1) != W or q[1][0] != f or q[1][1] != h:
        return None
    dtxt = q[1][2]
    if not _is_flag_strip(P[i + 3]) or not P[i + 3][1] or P[i + 3][1][0] != f:
        return None
    try:
        b_val, d_val = float.fromhex(btxt), float.fromhex(dtxt)
    except ValueError:
        return None
    repl = [lines[i + 1],
            "cqrt_x(%s)" % f,
            "cqrt_rz_i1(%s, %s)" % (f, btxt),
            "cqrt_x(%s)" % f,
            "cqrt_rz_i1(%s, %s)" % (f, _A_TOKEN)]
    return i + 3, repl, b_val + d_val, b_val, d_val


def reduce_3qlq(lines, allow_d=True):
    """Rewrite an OLD (pre-3qlq) trace into the register-free `cq_phi` form.

    -> (reduced_lines, counters, arec) where `arec` maps an index INTO
    `reduced_lines` to the (a_rec, B, D) of a class-(d) A gate awaiting
    `reconcile_angles`.

    Substitution priority — (b)-nest, (b)-flat, (d), (a), (c) — is not arbitrary:
    the nest's outer alloc must be claimed before the flat matcher sees it, and
    (d) must be claimed before its two halves fall through to (c) and (a)
    independently. A line no clause claims is copied through verbatim, which is
    what lets a golden mixing classes still reduce.
    """
    P = [parse(l) for l in lines]
    RS = work_rails(P)
    hgen = _handle_gen(lines)
    cnt = collections.Counter()
    out, arec, i = [], {}, 0
    while i < len(lines):
        m = match_nest(P, lines, i, RS, hgen)
        if m:
            j, repl, n_out, n_in = m
            out += repl
            cnt["b_nest"] += 1
            cnt["b_gates"] += n_out + n_in
            i = j
            continue
        m = match_route_region(P, i, RS)
        if m:
            j, flag, _base, arms = m
            _emit_kickback_arms(flag, arms, out, cnt, "b_gates")
            cnt["b"] += 1
            cnt["b_arms"] += len(arms)
            cnt["b_cswaps"] += 2 * len(arms)
            i = j
            continue
        if allow_d:
            m = match_angle_select_pair(P, lines, i)
            if m:
                j, repl, a_rec, b_val, d_val = m
                out += repl
                arec[len(out) - 1] = (a_rec, b_val, d_val)
                cnt["d"] += 1
                i = j
                continue
        p = P[i]
        if p and RZ_CTL.fullmatch(p[0] or "") and len(p[1]) == 3:
            out.append("cqrt_rz_i1(%s, %s)" % (p[1][0], p[1][2]))
            cnt["a"] += 1
            i += 1
            continue
        if p and RZ_UNC.fullmatch(p[0] or "") and len(p[1]) == 2:
            cnt["c"] += 1                       # DELETED (owner decision D2)
            try:
                if float.fromhex(p[1][1]) < 0:
                    cnt["c_adjoint"] += 1
            except ValueError:
                pass
            i += 1
            continue
        out.append(lines[i])
        i += 1
    # the nest legs are not counted by the flat branch above
    cnt["b_cswaps"] += 4 * cnt["b_nest"]
    return out, cnt, arec


def reconcile_angles(red, new, arec):
    """Substitute the NEW trace's own class-(d) A angle into the reduced trace.

    -> (red2, checks) where `checks` is a list of dicts, one per class-(d) A gate.
    A check that FAILS leaves `_A_TOKEN` in place, so the structural comparison
    fails too and the finding is reported twice rather than swallowed.

    Index-wise against the HANDLE-NORMALISED lists (`normalise` is
    index-preserving), because reduced-old and new number their handles
    differently; the ANGLE text taken from `new` carries no handle at all.
    """
    if not arec:
        return red, []
    rn, nn = normalise(red), normalise(new)
    red = list(red)
    checks = []
    for idx in sorted(arec):
        a_rec, b_val, d_val = arec[idx]
        rec = {"index": idx, "a_rec": a_rec, "B": b_val, "D": d_val,
               "a_new": None, "tol": None, "err": None, "ok": False,
               "why": ""}
        if len(rn) != len(nn) or idx >= len(nn):
            rec["why"] = ("line counts differ (reduced %d, new %d) — the "
                          "structural check owns this" % (len(rn), len(nn)))
            checks.append(rec)
            continue
        pr, pnw = parse(rn[idx]), parse(nn[idx])
        if not pr or not pnw or pr[0] != pnw[0] or len(pr[1]) != len(pnw[1]) \
                or pr[1][:-1] != pnw[1][:-1]:
            rec["why"] = "line %d is not the A gate: %r" % (idx + 1, nn[idx])
            checks.append(rec)
            continue
        try:
            a_new = float.fromhex(pnw[1][-1])
        except ValueError:
            rec["why"] = "new A angle %r does not parse as a hex float" % pnw[1][-1]
            checks.append(rec)
            continue
        tol = a_tolerance(a_new, d_val)
        err = abs(a_new - a_rec)
        rec.update({"a_new": a_new, "tol": tol, "err": err, "ok": err <= tol})
        if rec["ok"]:
            red[idx] = red[idx].replace(_A_TOKEN, parse(new[idx])[1][-1])
        else:
            rec["why"] = ("|A_new - fl(B+D)| = %.3e > tol %.3e" % (err, tol))
        checks.append(rec)
    return red, checks


def _rz_lines(lines):
    return [l for l in lines
            if parse(l) and (RZ_UNC.fullmatch(parse(l)[0] or "")
                             or RZ_CTL.fullmatch(parse(l)[0] or ""))]


def _ry_lines(lines):
    return [l for l in lines if parse(l) and RY_ANY.fullmatch(parse(l)[0] or "")]


def _count(lines, name):
    return sum(1 for l in lines if parse(l) and parse(l)[0] == name)


def classify_3qlq(old):
    """-> a short signature string for one OLD trace: which classes it bears.

    `NO-RZ` means Increment 1 must leave the golden BYTE-IDENTICAL, which is the
    assertion `audit_pair_3qlq` makes for it.
    """
    _red, cnt, arec = reduce_3qlq(old)
    parts = []
    if cnt["b_nest"]:
        parts.append("b-nest x%d" % cnt["b_nest"])
    if cnt["b"]:
        parts.append("b x%d(%d arm)" % (cnt["b"], cnt["b_arms"]))
    if cnt["d"]:
        parts.append("d? x%d" % cnt["d"])
    if cnt["a"]:
        parts.append("a x%d" % cnt["a"])
    if cnt["c"]:
        parts.append("c x%d" % cnt["c"])
    if not parts:
        return "NO-RZ" if not _rz_lines(old) else "UNREDUCED-RZ"
    return " + ".join(parts)


def audit_pair_3qlq(old, new, checks_out=None):
    """-> (status, detail, k_regions, k_arms, k_gates) for one golden, epic 3qlq.

    `checks_out`, if given, is a dict this fills with the individual check
    booleans (`b`, `a`, `ry`, `rz`, `cs`, `tf`, `d`, `scope`). It exists for
    `tools/golden_multiset_audit_test.py`'s layer 6, which pins each REPORT check
    to a mutant that makes it FALSE — see the redundancy note below.

    ⚠ WHICH CHECK IS ACTUALLY DOING THE WORK — MEASURED, NOT ASSUMED (kill test,
    2026-09-05: disable ONE check, re-run `golden_multiset_audit_test.py`, count
    the failures OUTSIDE its layer 6, which pins the checks deliberately).

        disabled   verdicts changed        disabled   verdicts changed
        (A)          0                     (A4)         0
        (A2)         0                     (A5)         0
        (A3)         0                     (D)          0
        (B)         11   <-- the only single deletion that changes a verdict

    (B) is line-for-line after handle normalisation, so it IMPLIES every other
    check on the family as it stands. The others are kept anyway, and it is
    worth being precise about why rather than calling them independent checks:
      * they turn "line 7 differs" into "the Ry stem moved" / "the new trace
        still emits cqrt_rz_i32_controlled" / "the cswap accounting is off",
        which is the difference between a diff a reviewer can act on and one
        they have to re-derive;
      * they are a real safety net if (B) is ever weakened — with (B) disabled
        they still catch all but SIX of the mutant family.
    Those six are worth knowing, because they are one class: `rz_i1` on the
    WRONG FLAG, two `rz_i1` SWAPPED, an `rz_i1` MOVED PAST THE STRIP, a nest's
    `rz_i1` on `fa` instead of the conjunction `g`, a nest's toffoli given the
    wrong controls, and a nest's inner mint left reading a rail. Every one is a
    HANDLE-IDENTITY or ORDER defect — exactly what the handle-INVARIANT (A)
    multiset is blind to by construction, and exactly the defects that put a
    phase on the wrong wire. Do not weaken (B).

    ⚠ AND ONE PAIR IS ONLY JOINTLY PINNED, which is the `CLAUDE.md` "a predicate
    with three arms and one probe" shape and is recorded rather than papered
    over. Mutant `n28` — a nest with an IF/ELSE inner region whose else arm is
    silently dropped — is caught by `match_nest`'s `len(arms) != 1` refusal
    (through (B), because the region is then copied through) OR by (A4)'s cswap
    accounting (which sees 8 removed where 4 were owed) — and MEASURED, deleting
    BOTH lets it through as `SUBSTITUTION-ONLY`. So (A4) is not merely a report:
    it is the second arm of that pair. `match_nest`'s depth-3 refusal
    (`base in RS`) is the same shape and its probe is `n29`.

    Checks, all ENFORCED:
      (S)  SCOPE — an OLD trace with NO `cqrt_rz` line is outside Increment 1 and
           must be byte-identical; and an OLD trace WITH one may not be unchanged
           (every Rz is either deleted or respelled `cqrt_rz_i1`, so an untouched
           golden means it was never regenerated).
      (A)  MULTISET — the handle-invariant delta must equal the delta the reducer
           itself performed, printed on every audited golden.
      (A2) Ry INVARIANCE — the Ry stem is untouched by this epic (PRD §5), so the
           handle-stripped multiset of `cqrt_ry*` lines must be IDENTICAL.
      (A3) Rz SPELLING — the NEW trace may contain no `cqrt_rz_*_controlled` and
           no `cqrt_rz_<W>` other than `cqrt_rz_i1` (PRD §5: the emitted set
           shrinks to that one symbol).
      (A4) CSWAP ACCOUNTING — every routed phase leg is gone: exactly
           `2 x arms + 4 x nests` removed and none moved.
      (A5) TOFFOLI ACCOUNTING — exactly `2 x nests` added (forward + LIFO undo).
      (D)  the class-(d) IEEE recovery of A, with the tolerance `a_tolerance`
           states; printed with the measured error whenever a (d) pair is present.
      (B)  STRUCTURAL — reduced-old must equal new LINE FOR LINE after handle
           normalisation. Strictly stronger than (A) on order.
    """
    if checks_out is None:
        checks_out = {}
    checks_out.update({"b": True, "a": True, "ry": True, "rz": True,
                       "cs": True, "tf": True, "d": True, "scope": True})
    old_rz = _rz_lines(old)
    if not old_rz:
        checks_out["scope"] = (old == new)
        if old == new:
            return ("UNCHANGED",
                    "no cqrt_rz line in the OLD trace: outside Increment 1's "
                    "scope and correctly UNCHANGED", 0, 0, 0)
        return ("OUT-OF-SCOPE",
                "this golden MOVED but its OLD trace has NO cqrt_rz line — "
                "Increment 1 touches only the Rz stem", 0, 0, 0)
    if old == new:
        checks_out["scope"] = False
        return ("FINDING",
                "(S) the OLD trace carries %d cqrt_rz line(s) but the golden is "
                "UNCHANGED — every Rz is either deleted (c) or respelled "
                "cqrt_rz_i1 (a/b/d), so this golden was never regenerated"
                % len(old_rz), 0, 0, 0)

    # The class-(d) ambiguity (see `match_angle_select_pair`) is resolved by
    # trying BOTH readings and reporting which one the new trace matched. The two
    # candidates differ in line count, so at most one can match.
    ambiguous = bool(reduce_3qlq(old, allow_d=True)[1]["d"])
    best = None
    for allow_d in (True, False):
        red, cnt, arec = reduce_3qlq(old, allow_d=allow_d)
        red, checks = reconcile_angles(red, new, arec)
        ok_b = normalise(red) == normalise(new)
        if best is None or (ok_b and not best[0]):
            best = (ok_b, allow_d, red, cnt, checks)
        if ok_b or not ambiguous:
            break
    ok_b, allow_d, red, cnt, checks = best

    co = collections.Counter(strip_handles(old))
    cn = collections.Counter(strip_handles(new))
    cr = collections.Counter(strip_handles(red))
    obs_old, obs_new = co - cn, cn - co
    exp_old, exp_new = co - cr, cr - co
    a_ok = (obs_old == exp_old and obs_new == exp_new)

    ry_ok = (collections.Counter(strip_handles(_ry_lines(old)))
             == collections.Counter(strip_handles(_ry_lines(new))))

    bad_rz = sorted({parse(l)[0] for l in _rz_lines(new)} - {"cqrt_rz_i1"})
    rz_ok = not bad_rz

    n_cs_old = _count(old, "cqrt_cswap")
    n_cs_new = _count(new, "cqrt_cswap")
    want_cs = cnt["b_cswaps"]
    cs_ok = (n_cs_old - n_cs_new == want_cs)

    n_tf_old = _count(old, "cqrt_toffoli")
    n_tf_new = _count(new, "cqrt_toffoli")
    tf_ok = (n_tf_new - n_tf_old == 2 * cnt["b_nest"])

    d_ok = all(c["ok"] for c in checks)
    checks_out.update({"b": ok_b, "a": a_ok, "ry": ry_ok, "rz": rz_ok,
                       "cs": cs_ok, "tf": tf_ok, "d": d_ok})

    detail = ("  (A) observed  -%s\n      observed  +%s\n"
              "      expected  -%s\n      expected  +%s"
              % (_fmt_counter(obs_old), _fmt_counter(obs_new),
                 _fmt_counter(exp_old), _fmt_counter(exp_new)))
    detail += ("\n  (A2) cqrt_ry multiset %s"
               % ("IDENTICAL" if ry_ok else "*** MOVED ***"))
    detail += ("\n  (A3) new-trace Rz spellings: %s"
               % ("cqrt_rz_i1 only" if rz_ok else "*** %s ***" % ", ".join(bad_rz)))
    detail += ("\n  (A4) cqrt_cswap %d -> %d (removed %d, expected 2 x %d arm(s) "
               "+ 4 x %d nest(s) = %d)"
               % (n_cs_old, n_cs_new, n_cs_old - n_cs_new, cnt["b_arms"],
                  cnt["b_nest"], want_cs))
    detail += ("\n  (A5) cqrt_toffoli %d -> %d (added %d, expected 2 x %d nest(s))"
               % (n_tf_old, n_tf_new, n_tf_new - n_tf_old, cnt["b_nest"]))
    for c in checks:
        if c["a_new"] is None:
            detail += "\n  (D) A NOT RECOVERED: %s" % c["why"]
        else:
            detail += ("\n  (D) A: new %s vs fl(B+D) %s — err %.3e, tol %.3e  %s"
                       % (_cfmt(c["a_new"]), _cfmt(c["a_rec"]), c["err"],
                          c["tol"], "ok" if c["ok"] else "*** OUT OF TOLERANCE ***"))
    detail += ("\n  (subs) a=%d  b=%d region(s)/%d arm(s)  b-nest=%d  c=%d "
               "(of which %d adjoint)  d=%d"
               % (cnt["a"], cnt["b"], cnt["b_arms"], cnt["b_nest"], cnt["c"],
                  cnt["c_adjoint"], cnt["d"]))

    nreg = cnt["b"] + cnt["b_nest"]
    narm = cnt["b_arms"] + cnt["b_nest"]
    ngate = cnt["a"] + cnt["b_gates"] + 2 * cnt["d"]

    if ok_b and a_ok and ry_ok and rz_ok and cs_ok and tf_ok and d_ok:
        st = "SUBSTITUTION-ONLY"
        if ambiguous:
            st = "AMBIGUOUS-d" if allow_d else "AMBIGUOUS-ca"
        return st, detail, nreg, narm, ngate

    parts = []
    if not ok_b:
        rn, nn = normalise(red), normalise(new)
        i = next((k for k in range(max(len(rn), len(nn)))
                  if k >= len(rn) or k >= len(nn) or rn[k] != nn[k]), 0)
        parts.append("(B) reduced-old != new at line %d\n     reduced-old: %s\n"
                     "     new        : %s"
                     % (i + 1,
                        rn[i] if i < len(rn) else "<end>",
                        nn[i] if i < len(nn) else "<end>"))
    if not a_ok:
        parts.append("(A) multiset delta is NOT the reducer's own substitution")
    if not ry_ok:
        parts.append("(A2) an Ry line changed — the Ry stem is untouched by 3qlq")
    if not rz_ok:
        parts.append("(A3) the NEW trace still emits %s" % ", ".join(bad_rz))
    if not cs_ok:
        parts.append("(A4) cqrt_cswap accounting is off")
    if not tf_ok:
        parts.append("(A5) cqrt_toffoli accounting is off")
    if not d_ok:
        parts.append("(D) the class-(d) A angle is not recoverable within tolerance")
    return "FINDING", "\n     ".join(parts) + "\n" + detail, nreg, narm, ngate


def git_show(rev, path):
    r = subprocess.run(["git", "show", "%s:%s" % (rev, path)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return r.stdout.splitlines()


def _fmt_counter(c, cap=8):
    items = sorted(c.items())
    body = ", ".join("%s x%d" % (k, v) for k, v in items[:cap])
    if len(items) > cap:
        body += ", … (%d more)" % (len(items) - cap)
    return "%d line(s) [%s]" % (sum(c.values()), body)


def audit(path, rev, epic="2a"):
    """-> (status, detail, k_regions, k_arms, k_gates) for one committed golden.

    No `verbose` parameter: the (A) delta is printed unconditionally now (the
    round-1 review's L3 F9 — a check nobody sees is a check nobody runs), so there
    is nothing left for a verbosity flag to reveal here. `--verbose` still governs
    the per-mutant detail in `--selftest`.
    """
    old = git_show(rev, path)
    if old is None:
        return "NEW-FILE", "not present at %s" % rev, 0, 0, 0
    new = open(path).read().splitlines()
    if epic == "3qlq":
        return audit_pair_3qlq(old, new)
    return audit_pair(old, new)


def audit_pair(old, new):
    """-> (status, detail, k_regions, k_arms, k_gates).

    Three checks, all ENFORCED (bd drbq Inc 2a round-1 review, L3 F1/F9):
      (S) SCOPE   — an out-of-scope (nested / switch) signature in the OLD trace
                    means the golden must be byte-identical old->new.
      (A) MULTISET — the §9.2 delta, handle-INVARIANT, must be exactly the
                    collapse arithmetic the reducer performed and nothing else.
                    Printed on EVERY audited golden, verbose or not.
      (B) STRUCTURAL — reduced-old must equal new line for line (order-sensitive).
    """
    # (S) SCOPE, asked FIRST and asked of the OLD trace, so it is answered even
    #     for a golden that did not move (where the answer is the assertion).
    scope = out_of_scope_signature(old)
    if old == new:
        d = "out-of-scope signature present and correctly UNCHANGED: %s" % scope \
            if scope else ""
        return "UNCHANGED", d, 0, 0, 0
    if scope:
        return ("OUT-OF-SCOPE",
                "this golden MOVED but bears a 4.3-nest signature, which Inc 2a "
                "does not collapse — %s" % scope, 0, 0, 0)

    red, nreg, narm, ngate, nneg = reduce_routes(old)
    rn, nn = normalise(red), normalise(new)

    # (A) THE §9.2 MULTISET DELTA, handle-INVARIANT and ENFORCED. `strip_handles`
    #     (every `hN` -> `h`) rather than `normalise` (renumber by first
    #     appearance), because the collapse DELETES a handle-minting line and
    #     first-appearance renumbering therefore shifts every later handle — which
    #     buries the arithmetic §9.2 asks for under renumbering noise. The
    #     observed delta must equal the delta the reducer itself performed: if
    #     they differ, the trace moved somewhere the reduction did not touch.
    co = collections.Counter(strip_handles(old))
    cn = collections.Counter(strip_handles(new))
    obs_old, obs_new = co - cn, cn - co
    exp_old, exp_new = expected_delta(old, narm, ngate, nneg)
    delta = ("  (A) observed  -%s\n      observed  +%s\n"
             "      expected  -%s\n      expected  +%s"
             % (_fmt_counter(obs_old), _fmt_counter(obs_new),
                _fmt_counter(exp_old), _fmt_counter(exp_new)))
    a_ok = (obs_old == exp_old and obs_new == exp_new)

    # (A2) CSWAP ACCOUNTING — exactly two per collapsed arm removed, none moved.
    n_cs_old = sum(1 for l in old if l.startswith("cqrt_cswap("))
    n_cs_new = sum(1 for l in new if l.startswith("cqrt_cswap("))
    cs_ok = (n_cs_old - n_cs_new == 2 * narm)
    delta += ("\n  (A2) cqrt_cswap %d -> %d (removed %d, expected 2 x %d arm(s))"
              % (n_cs_old, n_cs_new, n_cs_old - n_cs_new, narm))

    # (B) the strict order-sensitive check.
    b_ok = (rn == nn)

    if a_ok and cs_ok and b_ok:
        return "COLLAPSE-ONLY", delta, nreg, narm, ngate

    parts = []
    if not b_ok:
        i = next((k for k in range(max(len(rn), len(nn)))
                  if k >= len(rn) or k >= len(nn) or rn[k] != nn[k]), 0)
        parts.append("(B) reduced-old != new at line %d\n     reduced-old: %s\n"
                     "     new        : %s"
                     % (i + 1,
                        rn[i] if i < len(rn) else "<end>",
                        nn[i] if i < len(nn) else "<end>"))
    if not a_ok:
        parts.append("(A) multiset delta is NOT the reducer's own collapse")
    if not cs_ok:
        parts.append("(A2) cqrt_cswap accounting is off")
    return "FINDING", "\n     ".join(parts) + "\n" + delta, nreg, narm, ngate



# ═════════════════════════════════════════════════════════════════════════════
# --selftest — THE AUDIT'S OWN MUTANT VALIDATION (bd drbq Inc 2a round-1 review,
# L3 F1/F5/F9). "A checker nobody has tried to fool is a checker nobody should
# trust" — the same standard `tools/free_pairing_check_test.py` is held to.
#
# Every mutant below is applied to the NEW trace of an EMBEDDED (old, new) pair
# taken verbatim from the committed goldens, so the selftest needs no git, no
# build and no test tree. A mutant that comes back `COLLAPSE-ONLY` is a SURVIVOR
# and fails the run.
# ═════════════════════════════════════════════════════════════════════════════

# slice_control_phase_diamond — ONE non-negated arm, TWO gates.
_OLD_DIAMOND = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cqrt_rz_i32(h2, 0x1.8p-1)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_DIAMOND = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_rz_i32_controlled(h1, h0, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# slice_control_phase_ifne — ONE NEGATED arm (the `cqrt_x` bracket arithmetic:
# the route carries FOUR `cqrt_x`, control-in-place TWO).
_OLD_IFNE = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_x(h1)
cqrt_cswap(h1, h0, h2)
cqrt_x(h1)
cqrt_rz_i32(h2, 0x1p-2)
cqrt_x(h1)
cqrt_cswap(h1, h0, h2)
cqrt_x(h1)
cqrt_free(h2)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_IFNE = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_x(h1)
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_x(h1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# slice_control_seq_regions — TWO regions, so TWO flag frees (the aliasing probe).
_OLD_SEQ = """cqrt_alloc_i32(7) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cq_template_icmp_sgt_i32_hl(h0, 3) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_cswap(h3, h0, h4)
cqrt_rz_i32(h4, 0x1.8p-1)
cqrt_cswap(h3, h0, h4)
cqrt_free(h4)
cq_template_icmp_sgt_i32_hl_unc(h3, h0, 3)
cqrt_free(h3)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_SEQ = """cqrt_alloc_i32(7) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cq_template_icmp_sgt_i32_hl(h0, 3) -> h2
cqrt_rz_i32_controlled(h2, h0, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h2, h0, 3)
cqrt_free(h2)
cqrt_measure_i32(h0) -> 0""".splitlines()

# slice_control_nested_phase — the 4.3 depth-2 nest, which Inc 2a does NOT
# collapse. The OUT-OF-SCOPE mutant collapses its INNER region.
_OLD_NEST = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cq_template_icmp_slt_i32_hl(h2, 9) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_cswap(h3, h2, h4)
cqrt_rz_i32(h4, 0x1.8p-1)
cqrt_cswap(h3, h2, h4)
cqrt_free(h4)
cq_template_icmp_slt_i32_hl_unc(h3, h2, 9)
cqrt_free(h3)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_NEW_NEST_INNER_COLLAPSED = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1p-2)
cq_template_icmp_slt_i32_hl(h2, 9) -> h3
cqrt_rz_i32_controlled(h3, h2, 0x1.8p-1)
cq_template_icmp_slt_i32_hl_unc(h3, h2, 9)
cqrt_free(h3)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()


def _mv(L, frm, to):
    L = list(L)
    x = L.pop(frm)
    L.insert(to, x)
    return L


def _swap(L, a, b):
    L = list(L)
    L[a], L[b] = L[b], L[a]
    return L


def _drop(L, i):
    L = list(L)
    del L[i]
    return L


def _first(L, sub):
    return next(i for i, l in enumerate(L) if sub in l)


def _mutants():
    """-> [(name, old_lines, new_lines, note)] — L3's 20-mutant family."""
    D, ND = _OLD_DIAMOND, _NEW_DIAMOND
    F, NF = _OLD_IFNE, _NEW_IFNE
    S, NS = _OLD_SEQ, _NEW_SEQ
    g0 = _first(ND, "cqrt_rz_i32_controlled")          # 3
    unc = _first(ND, "_hl_unc")                        # 5
    out = []
    # ── a: ORDER ────────────────────────────────────────────────────────────
    out.append(("a1  cRz moved one line earlier", D, _mv(ND, g0, g0 - 1)))
    out.append(("a2  cRz moved past the flag strip", D, _mv(ND, g0, unc)))
    out.append(("a3  the two cRz of one spine swapped", D, _swap(ND, g0, g0 + 1)))
    out.append(("a4  two post-region lines swapped", D, _swap(ND, unc, unc + 1)))
    # ── b: ANGLE ────────────────────────────────────────────────────────────
    out.append(("b   theta changed 0x1p-2 -> 0x1p-3", D,
                [l.replace("0x1p-2", "0x1p-3") for l in ND]))
    # ── c: OPERANDS ─────────────────────────────────────────────────────────
    out.append(("c1  flag/handle SWAPPED in the cRz", D,
                [l.replace("(h1, h0,", "(h0, h1,") if "controlled" in l else l
                 for l in ND]))
    out.append(("c2  base -> a different live handle", D,
                [l.replace("(h1, h0,", "(h1, h1,") if "controlled" in l else l
                 for l in ND]))
    out.append(("c3  flag -> a different live handle", D,
                [l.replace("(h1, h0,", "(h0, h0,") if "controlled" in l else l
                 for l in ND]))
    # ── d/e: DELETION / EXTRA TRAFFIC ───────────────────────────────────────
    out.append(("d   the flag strip deleted", D, _drop(ND, unc)))
    out.append(("e1  extra cqrt_free appended", D, list(ND) + ["cqrt_free(h0)"]))
    out.append(("e2  extra cqrt_free mid-stream", D,
                ND[:g0] + ["cqrt_free(h0)"] + ND[g0:]))
    # ── f: THE cqrt_x BRACKET ARITHMETIC (negated arm) ──────────────────────
    xs = [i for i, l in enumerate(NF) if l.startswith("cqrt_x(")]
    out.append(("f1  one cqrt_x bracket dropped", F, _drop(NF, xs[0])))
    out.append(("f2  both cqrt_x brackets dropped", F,
                [l for l in NF if not l.startswith("cqrt_x(")]))
    out.append(("f3  an extra cqrt_x bracket added", F,
                NF[:xs[0]] + ["cqrt_x(h1)"] + NF[xs[0]:]))
    # ── g: THE ARM GATES THEMSELVES ─────────────────────────────────────────
    out.append(("g1  both arm gates dropped", D,
                [l for l in ND if "controlled" not in l]))
    out.append(("g2  one arm gate dropped", D, _drop(ND, g0)))
    # ── h: FREE ALIASING (needs two frees) ──────────────────────────────────
    fs = [i for i, l in enumerate(NS) if l.startswith("cqrt_free(")]
    out.append(("h   cqrt_free targets permuted", S, _swap(NS, fs[0], fs[1])))
    # ── i/j: STEM AND WIDTH ─────────────────────────────────────────────────
    out.append(("i   stem rz -> ry in the cRz", D,
                [l.replace("cqrt_rz_i32_controlled", "cqrt_ry_i32_controlled")
                 for l in ND]))
    out.append(("j   width i32 -> i64 in the cRz", D,
                [l.replace("cqrt_rz_i32_controlled", "cqrt_rz_i64_controlled")
                 for l in ND]))
    return out


def selftest(verbose=False):
    """-> exit code. 20 mutants + 4 controls + 1 out-of-scope probe."""
    print("=== CONTROLS (must be COLLAPSE-ONLY / UNCHANGED) ===")
    bad = 0
    controls = [("diamond (1 arm, 2 gates)", _OLD_DIAMOND, _NEW_DIAMOND, "COLLAPSE-ONLY"),
                ("ifne (1 NEGATED arm, 1 gate)", _OLD_IFNE, _NEW_IFNE, "COLLAPSE-ONLY"),
                ("seq_regions (2 regions)", _OLD_SEQ, _NEW_SEQ, "COLLAPSE-ONLY"),
                ("nested_phase, unchanged", _OLD_NEST, _OLD_NEST, "UNCHANGED")]
    for name, o, n, want in controls:
        st, detail, _r, _a, _g = audit_pair(o, n)
        ok = (st == want)
        bad += 0 if ok else 1
        print("  %-40s %-14s %s" % (name, st, "ok" if ok else "*** WRONG (want %s) ***" % want))
        if detail and (verbose or not ok):
            print("     " + detail.replace("\n", "\n     "))

    print("\n=== SCOPE PROBE (the L3 F1 gap) ===")
    st, detail, _r, _a, _g = audit_pair(_OLD_NEST, _NEW_NEST_INNER_COLLAPSED)
    ok = (st != "COLLAPSE-ONLY")
    bad += 0 if ok else 1
    print("  %-40s %-14s %s" % ("4.3 nest, INNER region collapsed", st,
                                "DETECTED" if ok else "*** SURVIVED ***"))
    if detail:
        print("     " + detail.replace("\n", "\n     "))

    print("\n=== MUTANTS (every one must be a FINDING) ===")
    for name, o, n in _mutants():
        st, detail, _r, _a, _g = audit_pair(o, n)
        ok = (st != "COLLAPSE-ONLY")
        bad += 0 if ok else 1
        print("  %-40s %-14s %s" % (name, st, "DETECTED" if ok else "*** SURVIVED ***"))
        if verbose or not ok:
            print("     " + (detail or "").replace("\n", "\n     "))

    n = len(_mutants())
    print("\n=== SELFTEST: %d mutant(s) + %d control(s) + 1 scope probe — %s ==="
          % (n, len(controls),
             "PASS, 0 survivors" if bad == 0 else "FAIL, %d problem(s)" % bad))
    return 1 if bad else 0


# ═════════════════════════════════════════════════════════════════════════════
# --epic 3qlq --selftest — the 3qlq mode's OWN mutant validation.
#
# EVERY "new" trace below is HAND-WRITTEN from PRD §3 / §10.2, never produced by
# `reduce_3qlq`. Generating them with the reducer would make the controls pass by
# construction and prove nothing; hand-writing them is what lets a control FAIL
# when the reducer's model is wrong. The "old" traces are verbatim committed
# goldens (or the pre-2a routed traces already embedded above for the 2a mode).
#
# The full self-test lives in `tools/golden_multiset_audit_test.py`, which drives
# THIS function plus a wider family; keeping the core family embedded here means
# `--epic 3qlq --selftest` needs no second file, no git, no build and no test tree.
# ═════════════════════════════════════════════════════════════════════════════

# ── class (a): the committed slice_control_phase_diamond (post-2a) ───────────
_Q_OLD_A = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_rz_i32_controlled(h1, h0, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_Q_NEW_A = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)
cqrt_rz_i1(h1, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (a) NEGATED: the committed slice_control_phase_ifne (post-2a) ──────
_Q_OLD_ANEG = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_x(h1)
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_x(h1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_Q_NEW_ANEG = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1p-2)
cqrt_x(h1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (c) + (a): the committed slice_control_phase_ifelse_derived. The
#    unconditional pre-region Rz sits IMMEDIATELY before the mint, so this is the
#    measured counter-example that clause 4 of `match_angle_select_pair` exists
#    for: without it the reducer would read the first two lines as a 2b pair.
_Q_OLD_CA = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_rz_i32(h0, 0x1.ccccccccccccdp-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)
cqrt_rz_i32_controlled(h1, h0, 0x1p-3)
cqrt_x(h1)
cqrt_rz_i32_controlled(h1, h0, 0x1.8p-1)
cqrt_x(h1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

_Q_NEW_CA = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)
cqrt_rz_i1(h1, 0x1p-3)
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.8p-1)
cqrt_x(h1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (b) FLAT: `_OLD_DIAMOND` (pre-2a routed, 1 arm, 2 gates) ───────────
_Q_NEW_B = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)
cqrt_rz_i1(h1, 0x1.8p-1)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (b) FLAT, NEGATED: `_OLD_IFNE` (four cqrt_x become two) ────────────
_Q_NEW_BNEG = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1p-2)
cqrt_x(h1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (b) SWITCH: the committed slice_control_switch_phase (3 regions) ───
_Q_OLD_SWITCH = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cqrt_rz_i32(h2, 0x1.999999999999ap-4)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cq_template_icmp_eq_i32_hl(h0, 1) -> h3
cqrt_alloc_i32(0) -> h4
cqrt_cswap(h3, h0, h4)
cqrt_rz_i32(h4, 0x1.999999999999ap-3)
cqrt_cswap(h3, h0, h4)
cqrt_free(h4)
cq_template_icmp_eq_i32_hl_unc(h3, h0, 1)
cqrt_free(h3)
cq_template_icmp_eq_i32_hl(h0, 2) -> h5
cqrt_alloc_i32(0) -> h6
cqrt_cswap(h5, h0, h6)
cqrt_rz_i32(h6, 0x1.3333333333333p-2)
cqrt_cswap(h5, h0, h6)
cqrt_free(h6)
cq_template_icmp_eq_i32_hl_unc(h5, h0, 2)
cqrt_free(h5)
cqrt_measure_i32(h0) -> 0""".splitlines()

_Q_NEW_SWITCH = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 0) -> h1
cqrt_rz_i1(h1, 0x1.999999999999ap-4)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 0)
cqrt_free(h1)
cq_template_icmp_eq_i32_hl(h0, 1) -> h2
cqrt_rz_i1(h2, 0x1.999999999999ap-3)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 1)
cqrt_free(h2)
cq_template_icmp_eq_i32_hl(h0, 2) -> h3
cqrt_rz_i1(h3, 0x1.3333333333333p-2)
cq_template_icmp_eq_i32_hl_unc(h3, h0, 2)
cqrt_free(h3)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (b) NEST: `_OLD_NEST` -> the PRD §3 conjunction flag. ⚠ MODEL, not a
#    measured trace (see `match_nest`). Note the inner mint/strip now read h0,
#    the ORIGINAL register, because nothing routes it onto a rail any more.
_Q_NEW_NEST = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)
cq_template_icmp_slt_i32_hl(h0, 9) -> h2
cqrt_alloc_i1(0) -> h3
cqrt_toffoli(h1, h2, h3)
cqrt_rz_i1(h3, 0x1.8p-1)
cqrt_toffoli(h1, h2, h3)
cqrt_free(h3)
cq_template_icmp_slt_i32_hl_unc(h2, h0, 9)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0""".splitlines()

# ── class (c): a forward Rz AND its negated-angle adjoint, both deleted. The
#    spine is `slice_uncompute_dead_dag`'s h1 chain, trimmed.
_Q_OLD_C = """cqrt_alloc_i32(2) -> h0
cqrt_ry_i32(h0, 0x1p-2)
cq_template_shl_i32_hl(h0, 2) -> h1
cqrt_rz_i32(h1, 0x1p-1)
cqrt_rz_i32(h1, -0x1p-1)
cq_template_shl_i32_hl_unc(h1, h0, 2)
cqrt_free(h1)
cqrt_ry_i32(h0, -0x1p-2)
cqrt_free(h0)""".splitlines()

_Q_NEW_C = """cqrt_alloc_i32(2) -> h0
cqrt_ry_i32(h0, 0x1p-2)
cq_template_shl_i32_hl(h0, 2) -> h1
cq_template_shl_i32_hl_unc(h1, h0, 2)
cqrt_free(h1)
cqrt_ry_i32(h0, -0x1p-2)
cqrt_free(h0)""".splitlines()

# ── class (d): the committed slice_control_angle_select_rz. B = 0.3,
#    D = fl(0.9 - 0.3), and the NEW trace carries the TRUE A = 0.9, which is ONE
#    ULP below `fl(B + D)` — the measurement that forces `a_tolerance`.
_Q_OLD_D = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_alloc_i32(7) -> h1
cqrt_ry_i32(h1, 0x1p-2)
cqrt_rz_i32(h1, 0x1.3333333333333p-2)
cq_template_icmp_eq_i32_hl(h0, 5) -> h2
cqrt_rz_i32_controlled(h2, h1, 0x1.3333333333334p-1)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
cqrt_measure_i32(h0) -> 0
cqrt_measure_i32(h1) -> 0""".splitlines()


def _q_new_d(a_text="0x1.ccccccccccccdp-1"):
    return ("""cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_alloc_i32(7) -> h1
cqrt_ry_i32(h1, 0x1p-2)
cq_template_icmp_eq_i32_hl(h0, 5) -> h2
cqrt_x(h2)
cqrt_rz_i1(h2, 0x1.3333333333333p-2)
cqrt_x(h2)
cqrt_rz_i1(h2, %s)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
cqrt_measure_i32(h0) -> 0
cqrt_measure_i32(h1) -> 0""" % a_text).splitlines()


# ── the NO-RZ scope control: a 4.2 value diamond, which Increment 1 must leave
#    byte-identical (it carries `cqrt_cswap` but no `cqrt_rz` at all).
_Q_OLD_NORZ = """cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_cswap(h1, h0, h2)
cq_template_mul_i32_hl(h2, 5) -> h3
cqrt_cswap(h1, h0, h3)
cqrt_alloc_i32(0) -> h4
cqrt_copy_i32(h0, h4)
cqrt_cswap(h1, h0, h3)
cq_template_mul_i32_hl_unc(h3, h2, 5)
cqrt_cswap(h1, h0, h2)
cqrt_free(h2)
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h4) -> 0""".splitlines()


def _q_controls():
    """-> [(name, old, new, want_status_set)] — must all come back a PASS status."""
    ok = ("SUBSTITUTION-ONLY",)
    return [
        ("(a) flat 2a line -> rz_i1", _Q_OLD_A, _Q_NEW_A, ok),
        ("(a) NEGATED arm, x-bracket kept", _Q_OLD_ANEG, _Q_NEW_ANEG, ok),
        ("(c)+(a) ifelse_derived (NOT a 2b pair)", _Q_OLD_CA, _Q_NEW_CA, ok),
        ("(b) routed quintuple -> one rz_i1", _OLD_DIAMOND, _Q_NEW_B, ok),
        ("(b) routed NEGATED (4 cqrt_x -> 2)", _OLD_IFNE, _Q_NEW_BNEG, ok),
        ("(b) switch, 3 per-case flags", _Q_OLD_SWITCH, _Q_NEW_SWITCH, ok),
        ("(b) NEST -> toffoli conjunction", _OLD_NEST, _Q_NEW_NEST, ok),
        ("(c) uncontrolled Rz + adjoint deleted", _Q_OLD_C, _Q_NEW_C, ok),
        ("(d) 2b pair -> the exact two-gate form", _Q_OLD_D, _q_new_d(),
         ("AMBIGUOUS-d",)),
        ("no-rz golden, correctly UNCHANGED", _Q_OLD_NORZ, _Q_OLD_NORZ,
         ("UNCHANGED",)),
    ]


def _q_probes():
    """-> [(name, old, new, why)] — each must come back a FINDING / OUT-OF-SCOPE."""
    import math
    a_rec = float.fromhex("0x1.3333333333333p-2") + \
        float.fromhex("0x1.3333333333334p-1")
    d_val = float.fromhex("0x1.3333333333334p-1")
    # walk UP from fl(B+D) until we are strictly outside the tolerance, and keep
    # the last value that is still INSIDE it. Both are asserted, so the constant
    # `A_TOL_REL` is pinned from BOTH sides rather than being decoration.
    inside, x = a_rec, a_rec
    for _ in range(64):
        nxt = math.nextafter(x, math.inf)
        if abs(nxt - a_rec) > a_tolerance(nxt, d_val):
            break
        inside, x = nxt, nxt
    outside = math.nextafter(x, math.inf)

    A, NA = _Q_OLD_A, _Q_NEW_A
    B, NB = _OLD_DIAMOND, _Q_NEW_B
    N, NN = _OLD_NEST, _Q_NEW_NEST
    S, NS = _Q_OLD_SWITCH, _Q_NEW_SWITCH
    C, NC = _Q_OLD_C, _Q_NEW_C
    g = _first(NA, "cqrt_rz_i1")
    unc = _first(NA, "_hl_unc")
    out = [
        ("m1  the flag strip dropped", A, _drop(NA, unc)),
        ("m2  the flag free dropped", A, _drop(NA, _first(NA, "cqrt_free"))),
        ("m3  wrong theta on the new rz_i1", A,
         [l.replace("0x1p-2", "0x1p-3") for l in NA]),
        ("m4  rz_i1 on the WRONG flag", A,
         [l.replace("cqrt_rz_i1(h1,", "cqrt_rz_i1(h0,") for l in NA]),
        ("m5  a _controlled line SURVIVES", A,
         [l.replace("cqrt_rz_i1(h1, 0x1p-2)",
                    "cqrt_rz_i32_controlled(h1, h0, 0x1p-2)") for l in NA]),
        ("m6  a cqrt_cswap SURVIVES", B,
         NB[:g] + ["cqrt_alloc_i32(0) -> h9", "cqrt_cswap(h1, h0, h9)",
                   "cqrt_cswap(h1, h0, h9)", "cqrt_free(h9)"] + NB[g:]),
        ("m7  an Ry line CHANGED", A,
         [l.replace("cqrt_ry_i32(h0, 0x1p-1)", "cqrt_ry_i32(h0, 0x1p-2)")
          for l in NA]),
        ("m8  (d) A beyond tolerance", _Q_OLD_D, _q_new_d(_cfmt(outside))),
        ("m9  (c) applied where (a) was owed", A,
         [l for l in NA if "cqrt_rz_i1" not in l]),
        ("m10 the two rz_i1 of one arm swapped", A, _swap(NA, g, g + 1)),
        ("m11 an rz_i1 moved past the flag strip", A, _mv(NA, g, unc)),
        ("m12 an extra cqrt_free appended", A, list(NA) + ["cqrt_free(h0)"]),
        ("m13 the negated arm's cqrt_x dropped", _Q_OLD_ANEG,
         _drop(_Q_NEW_ANEG, _first(_Q_NEW_ANEG, "cqrt_x"))),
        ("m14 an extra cqrt_x bracket added", _Q_OLD_ANEG,
         _Q_NEW_ANEG[:2] + ["cqrt_x(h1)"] + _Q_NEW_ANEG[2:]),
        ("m15 (b-nest) the toffoli UNDO dropped", N,
         _drop(NN, len(NN) - 1 - NN[::-1].index("cqrt_toffoli(h1, h2, h3)"))),
        ("m16 (b-nest) the conjunction free dropped", N,
         _drop(NN, _first(NN, "cqrt_free(h3)"))),
        ("m17 (b-nest) rz_i1 on fa, not on g", N,
         [l.replace("cqrt_rz_i1(h3,", "cqrt_rz_i1(h1,") for l in NN]),
        ("m18 (b-nest) toffoli controls wrong", N,
         [l.replace("cqrt_toffoli(h1, h2, h3)", "cqrt_toffoli(h2, h2, h3)")
          for l in NN]),
        ("m19 (c) only the FORWARD Rz deleted", C,
         NC[:3] + ["cqrt_rz_i32(h1, -0x1p-1)"] + NC[3:]),
        ("m20 (d) both cqrt_x brackets dropped", _Q_OLD_D,
         [l for l in _q_new_d() if not l.startswith("cqrt_x(")]),
        ("m21 (d) A and B swapped between arms", _Q_OLD_D,
         _swap(_q_new_d(), _first(_q_new_d(), "0x1.3333333333333p-2"),
               _first(_q_new_d(), "0x1.ccccccccccccdp-1"))),
        ("m22 (b-switch) one case's rz_i1 dropped", S,
         _drop(NS, _first(NS, "0x1.999999999999ap-3"))),
        ("m23 the new Rz is rz_i8, not rz_i1", A,
         [l.replace("cqrt_rz_i1(", "cqrt_rz_i8(") for l in NA]),
        ("m24 a no-rz golden MOVED", _Q_OLD_NORZ,
         list(_Q_OLD_NORZ) + ["cqrt_free(h0)"]),
        ("m25 a golden with Rz left UNCHANGED", A, list(A)),
    ]
    return out, inside, outside, a_rec, d_val


def selftest_3qlq(verbose=False):
    """-> exit code. Hand-written controls + the mutant family + the tolerance pin."""
    probes, inside, outside, a_rec, d_val = _q_probes()
    bad = 0

    print("=== CONTROLS (--epic 3qlq; every NEW trace is HAND-WRITTEN) ===")
    controls = _q_controls()
    for name, o, n, want in controls:
        st, detail, _r, _a, _g = audit_pair_3qlq(o, n)
        okc = st in want
        bad += 0 if okc else 1
        print("  %-44s %-20s %s"
              % (name, st, "ok" if okc else "*** WRONG (want %s) ***"
                 % "/".join(want)))
        if detail and (verbose or not okc):
            print("     " + detail.replace("\n", "\n     "))

    print("\n=== TOLERANCE PIN (class (d), both sides of A_TOL_REL) ===")
    tol_rows = [("A = fl(B+D) + the LARGEST in-tolerance step", inside, True),
                ("A = one step FURTHER (must be rejected)", outside, False)]
    for name, a_val, want_ok in tol_rows:
        st, detail, _r, _a, _g = audit_pair_3qlq(_Q_OLD_D, _q_new_d(_cfmt(a_val)))
        got_ok = (st == "AMBIGUOUS-d")
        okc = (got_ok == want_ok)
        bad += 0 if okc else 1
        print("  %-44s %-20s %s (err %.4e, tol %.4e)"
              % (name, st, "ok" if okc else "*** WRONG ***",
                 abs(a_val - a_rec), a_tolerance(a_val, d_val)))
        if detail and (verbose or not okc):
            print("     " + detail.replace("\n", "\n     "))

    print("\n=== MUTANTS (every one must be a FINDING / OUT-OF-SCOPE) ===")
    for name, o, n in probes:
        st, detail, _r, _a, _g = audit_pair_3qlq(o, n)
        okc = st in ("FINDING", "OUT-OF-SCOPE")
        bad += 0 if okc else 1
        print("  %-44s %-20s %s" % (name, st,
                                    "DETECTED" if okc else "*** SURVIVED ***"))
        if verbose or not okc:
            print("     " + (detail or "").replace("\n", "\n     "))

    print("\n=== SELFTEST (3qlq): %d mutant(s) + %d control(s) + 2 tolerance "
          "pin(s) — %s ==="
          % (len(probes), len(controls),
             "PASS, 0 survivors" if bad == 0 else "FAIL, %d problem(s)" % bad))
    return 1 if bad else 0


def dryrun_3qlq(paths, rev, verbose=False):
    """`--epic 3qlq --dryrun` — audit each OLD golden against the tool's OWN
    reduction of it (self-consistency), BEFORE any real new golden exists.

    ⚠ WHAT THIS DOES AND DOES NOT ESTABLISH. It proves (i) the reducer terminates
    and produces a well-formed trace on every real golden in the tree, (ii) the
    seven checks of `audit_pair_3qlq` agree with the reducer's own arithmetic on
    all of them, and (iii) which substitution class each golden falls in. It
    proves NOTHING about the compiler: reduce(old) is the tool's MODEL of the new
    trace, so a green dry run is a claim about the tool, not about Increment 1.
    The class-(d) `@A@` placeholder is materialised here as `%a`-formatted
    `fl(B + D)`, which is 1 ulp off the true source angle on the flagship golden —
    so this mode also exercises the `a_tolerance` path rather than side-stepping it.
    """
    bad = 0
    tally = collections.Counter()
    for p in sorted(paths):
        old = git_show(rev, p)
        if old is None:
            print("!! %-58s NEW-FILE" % os.path.basename(p))
            tally["NEW-FILE"] += 1
            bad += 1
            continue
        red, _cnt, arec = reduce_3qlq(old)
        for idx, (a_rec, _b, _d) in arec.items():
            red[idx] = red[idx].replace(_A_TOKEN, _cfmt(a_rec))
        st, detail, nreg, narm, ngate = audit_pair_3qlq(old, red)
        tally[st] += 1
        mark = "!!" if st in ("FINDING", "OUT-OF-SCOPE") else "  "
        print("%s %-58s %-18s %s  [k=%d region(s), %d arm(s), %d gate(s)]"
              % (mark, os.path.basename(p), st, classify_3qlq(old),
                 nreg, narm, ngate))
        if detail and (verbose or st in ("FINDING", "OUT-OF-SCOPE")):
            print("     " + detail.replace("\n", "\n     "))
        if st in ("FINDING", "OUT-OF-SCOPE"):
            bad += 1
    print("\n=== DRY-RUN TALLY (%d golden(s) at %s) ===" % (len(paths), rev))
    for k, v in sorted(tally.items()):
        print("  %-18s %d" % (k, v))
    print("  %s" % ("PASS — the reducer is self-consistent on every golden"
                    if bad == 0 else "FAIL — %d golden(s)" % bad))
    return 1 if bad else 0


def classify_report(paths, rev):
    """`--epic 3qlq --classify` — which substitution class each OLD golden bears.

    Asked of the OLD trace at `rev`, so it can be run BEFORE any golden has been
    regenerated. This is the map the orchestrator uses when the real new goldens
    arrive; the table it prints is transcribed into this file's header.
    """
    rows, tally = [], collections.Counter()
    for p in sorted(paths):
        old = git_show(rev, p)
        if old is None:
            rows.append((os.path.basename(p), "NEW-FILE"))
            tally["NEW-FILE"] += 1
            continue
        sig = classify_3qlq(old)
        rows.append((os.path.basename(p), sig))
        tally[sig.split(" +")[0].split(" x")[0]] += 1
    for name, sig in rows:
        print("  %-58s %s" % (name, sig))
    print("\n=== CLASS TALLY (%d golden(s) at %s) ===" % (len(rows), rev))
    for k, v in sorted(tally.items()):
        print("  %-16s %d" % (k, v))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("goldens", nargs="*",
                    help="paths to audit (default: every CHANGED tests/e2e golden)")
    ap.add_argument("--rev", default="HEAD",
                    help="git revision holding the OLD goldens (default HEAD)")
    ap.add_argument("--all", action="store_true",
                    help="audit every tests/e2e golden, not only the changed ones")
    ap.add_argument("--epic", default="2a", choices=["2a", "3qlq"],
                    help="which admitted substitution set to enforce: `2a` (the "
                         "drbq Inc-2a route->cRz collapse, the default) or "
                         "`3qlq` (the register-free cq_phi substitutions (a)-(d) "
                         "of retire-swap-route-PRD §10.2)")
    ap.add_argument("--classify", action="store_true",
                    help="--epic 3qlq only: print which substitution class each "
                         "OLD golden bears, without auditing a new one")
    ap.add_argument("--dryrun", action="store_true",
                    help="--epic 3qlq only: audit each OLD golden against the "
                         "tool's OWN reduction of it (self-consistency). Proves "
                         "the reducer, NOT the compiler")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--selftest", action="store_true",
                    help="run the audit's own mutant validation (needs no git, "
                         "no build, no test tree) and exit")
    cfg = ap.parse_args()

    if cfg.selftest:
        return selftest(cfg.verbose) if cfg.epic == "2a" \
            else selftest_3qlq(cfg.verbose)

    paths = cfg.goldens
    if not paths:
        if cfg.all:
            paths = sorted(p for p in os.listdir("tests/e2e")
                           if p.endswith(".expected.log"))
            paths = [os.path.join("tests/e2e", p) for p in paths]
        else:
            # CHANGED **and** UNTRACKED (bd drbq Inc 2a round-1 review, L3 F5).
            # `git diff --name-only` lists only TRACKED modifications, so a
            # brand-new golden — exactly the one nobody has ever audited — was
            # silently skipped, and its `NEW-FILE` status could only ever appear
            # when a path was passed explicitly. Measured: `git diff --name-only
            # HEAD -- tools` omitted the then-untracked
            # `tools/golden_multiset_audit.py` itself.
            r = subprocess.run(["git", "diff", "--name-only", cfg.rev, "--",
                                "tests/e2e"], capture_output=True, text=True)
            u = subprocess.run(["git", "ls-files", "--others",
                                "--exclude-standard", "--", "tests/e2e"],
                               capture_output=True, text=True)
            paths = sorted({p for p in (r.stdout + "\n" + u.stdout).split()
                            if p.endswith(".expected.log")})
    if not paths:
        print("golden_multiset_audit: no goldens to audit")
        return 0

    if cfg.classify or cfg.dryrun:
        if cfg.epic != "3qlq":
            print("golden_multiset_audit: --classify/--dryrun need --epic 3qlq")
            return 2
        if cfg.classify and cfg.dryrun:
            print("golden_multiset_audit: pass --classify OR --dryrun, not both")
            return 2
        return (classify_report(paths, cfg.rev) if cfg.classify
                else dryrun_3qlq(paths, cfg.rev, cfg.verbose))

    bad = 0
    tally = collections.Counter()
    treg = tarm = tgate = 0
    for p in sorted(paths):
        st, detail, nreg, narm, ngate = audit(p, cfg.rev, cfg.epic)
        tally[st] += 1
        treg += nreg
        tarm += narm
        tgate += ngate
        mark = "!!" if st in ("FINDING", "OUT-OF-SCOPE") else "  "
        extra = ""
        if st in ("COLLAPSE-ONLY", "SUBSTITUTION-ONLY",
                  "AMBIGUOUS-d", "AMBIGUOUS-ca"):
            extra = "  k=%d region(s), %d arm(s), %d gate(s)" % (nreg, narm, ngate)
        print("%s %-58s %s%s" % (mark, os.path.basename(p), st, extra))
        if detail:
            print("     " + detail.replace("\n", "\n     "))
        if st in ("FINDING", "OUT-OF-SCOPE"):
            bad += 1

    print("\n=== TALLY (%d golden(s) vs %s, --epic %s) ==="
          % (len(paths), cfg.rev, cfg.epic))
    for k, v in sorted(tally.items()):
        print("  %-18s %d" % (k, v))
    print("  routes collapsed: %d region(s), %d arm(s), %d rz gate(s)"
          % (treg, tarm, tgate))
    if tally["AMBIGUOUS-d"] or tally["AMBIGUOUS-ca"]:
        print("  ⚠ %d golden(s) bear the class-(d) / class-(c)+(a) trace ambiguity "
              "(`match_angle_select_pair`). The audit resolved each against the "
              "NEW trace and reports WHICH reading matched; it CANNOT say the "
              "compiler picked the reading the SOURCE meant — check the .c."
              % (tally["AMBIGUOUS-d"] + tally["AMBIGUOUS-ca"]))
    label = ("every diff is the collapse and nothing else" if cfg.epic == "2a"
             else "every diff is one of the four PRD §10.2 substitutions and "
                  "nothing else")
    print("  %s" % ("PASS — %s" % label if bad == 0
                    else "FAIL — %d golden(s) moved otherwise" % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
