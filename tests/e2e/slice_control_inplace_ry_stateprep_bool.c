/* slice_control_inplace_ry_stateprep_bool.c — THE SLICE THE 2026-09-11 OWNER
   RULING EXISTS FOR (bd `drbq.14`; F2's `CondWire` narrowing).

   OWNER RULING, verbatim: *"WE DO NOT WANT TO WRITE `int b1`. also WE DO NOT
   WANT ANOTHER cq function. it should just be an application of gates … I dont
   see the need for the over-decline."*

   BEFORE THE RULING THIS PROGRAM DECLINED — `state prep seed is proven equal to
   the condition register under quantum control` — and the only workaround was
   to widen `r` to `int`, which is the sentence the owner refused. It is not a
   width bug and there is no `i1` clause anywhere in F2: the collision is a
   CONSEQUENCE of F2's candidate list. The branch's own condition is a tainted
   `i1` that dominates the branch, and `LazyValueInfo` pins it to `{true}` on one
   edge and `{false}` on the other — so EVERY `_Bool` seed matched one of the two
   edges, whatever it was. That is the whole of the retired "THE `i1`
   STATE-PREP WIDTH IS OUT".

   WHAT LOWERS NOW — gates and nothing else. No new `cq_*` function, no new
   runtime symbol, no YAML row; the emitted set is the drbq Inc-4 state-prep
   stream at `i1`:

       cqrt_alloc_i1(0)                  the `_Bool` rail, prepared to the SEED
       cqrt_ry_i1_controlled(f, h, θ)    the arm, under the ordinary flag

   READ THE GOLDEN LINE BY LINE, against the analytic stream:
     1  cqrt_alloc_i32(0)             — `q`'s rail, seeded from the classical 0
     2  cqrt_ry_i32(h0, 0.5)          — `q`'s own (UNCONTROLLED) rotation
     3  cq_template_icmp_eq_i32_hl    — the FLAG, minted at the compare
     4  cqrt_alloc_i1(0)              — the PREPPED rail: `_Bool r = 0`
     5  cqrt_ry_i1_controlled(h1,h2,·)— the arm gate, controlled on the flag
     6  cq_template_icmp_eq_i32_hl_unc— the STRIP, same operands as line 3
     7  cqrt_free(h1)                 — the flag, and the ONLY free in the region
     8  cqrt_measure_i32(h0)          — `q`, untouched by the region
     9  cqrt_measure_i1(h2)           — `r`
   Note what is NOT there: no route, no `cqrt_cswap`, no work rail, no
   reverse-play, no `cqrt_x` (the polarity twin below is where the bracket
   appears), and NO free of h2 — the prepped rail is FROZEN
   (`ChainWalk::railCarriesControlledRotation`), because a controlled gate's
   adjoint needs its control and the flag is freed on line 7. Left allocated is
   Rule 6's sanctioned fallback; freeing it would be a dirty free of a
   condition-entangled rail.

   ⚠ WHAT THIS GOLDEN DOES NOT WITNESS, said because the comfortable reading is
   wrong. No trace can answer a STATE question: the runtime prints symbols and
   handles, so "the fresh rail holds |0> on the f=0 branch" is invisible to it,
   and `free_pairing_check.py` classifies `cqrt_alloc_<W>` BY SYMBOL NAME and
   never reads the seed argument — a WRONG SEED IS INVISIBLE TO STAGE 2b at
   every site. What both gates pin is the STRUCTURE. Stage 2b runs STRICT here
   for what it does cover: no use-after-free of the flag, no dirty free.

   ⚠ AND THIS IS NOT THE OWNER'S `grover_oracle_uncompute.c`. That file is
   conditioned on a BARE RAIL (`br i1 %b0`, no compare) and declines at `bare i1
   register condition` (bd `l4x4`), behind a two-merge-phi `control flow` decline
   (bd `b6ap`). F2 was wall 3 of 3 and only wall 3 moved.

   ⚠ UPDATED BY bd `test_C_libtooling-l4x4` sub-increment l4x4.b: WALL 2 HAS
   SINCE MOVED TOO. The bare-rail spelling of this very program now LOWERS — the
   fixture this header used to cite as *"that fact as a fixture"*,
   `control_inplace_ry_reject_stateprep_rail_i1_seed_l4x4.ll`, was `git mv`'d to
   `ir-pass/test/control_inplace_ry_stateprep_rail_i1_seed.ll` with its IR
   BYTE-UNCHANGED and rewritten as the ACCEPT its own retirement note predicted.
   ⚠ AND WALL 1 HAS MOVED TOO: bd `b6ap`'s multi-phi peel landed on `main`
   3a3a2b9, so ALL THREE WALLS ARE DOWN and the owner's FILE COMPILES (measured
   at the second merge: 19 trace lines, stage 2b `1 verified, 0 violation(s), 0
   unproven`; `MERGE_l4x4_2.md` §4). Its second region alone is pinned by
   `slice_control_inplace_ry_bool_stateprep_negated`. This slice is unchanged and
   still measures what it always did — the COMPARE-conditioned spelling.

   ⚠ THE TRADE THE RULING BUYS, disclosed rather than fenced: after `-O1` this
   module is indistinguishable from a source that rotated the CONDITION's own
   register in place, which CQ has never lowered and which declines in every
   spelling that survives `-O1` intact (measured 19/19 + 13 plain-C, SCOPE §2.2).
   `ir-pass/test/control_inplace_ry_stateprep_selfcontrolled_folded_as_prep.ll`
   carries that measurement.

   (Every `probes/...` reference above is relative to this increment's scoping
   record, `docs/prd/phase-04-swap-route-control/inc1-records/session-f2-i1/`.) */
int slice(void) {
    int  q = 0; cq_theta(&q, 0.5); /* the condition register                    */
    _Bool r = 0;                   /* the `_Bool` seed — F2's old collider       */
    if (q == 1) {                  /* tainted condition -> flag mint at the icmp */
        cq_theta(&r, 0.9);         /* `r` is classically 0 here: a STATE PREP    */
    }
    return (int) cq_measure(q) + (int) cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
