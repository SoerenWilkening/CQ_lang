/* slice_control_stateprep_bool_loop_iterlocal.c — bd `test_C_libtooling-wx8g`,
   R7-loop CLAUSE (c) on the CONTROLLED STATE PREP branch.

       for (k < K) { int r = 7;                     // the classical SEED
                     if (b) { r = 7; cq_theta(&r, .2); }  // prep, under a `_Bool`
                     s += cq_measure(r); }

   A state prep has NO pre-region SSA name for its rail at all — the hoisted
   theta mints it — which is why R4/R6 are SKIPPED for this class (§14.5) and
   why `BaseWireOrder` is EMPTY. Clause (b) therefore had no member to look at
   and `Rollable` stayed false for every in-loop prep ever written; clause (c)
   asks its question of the HOISTED GATE instead (`MintSeed = T`).

   ⚠ THE PER-ACTIVATION RESET QUESTION IS ANSWERED BY NOT HOISTING. The shipped
   decline fixture's header read the obstruction as positional and concluded a
   rolled in-loop prep "would need the alloc hoisted OUT of the loop … trip 2's
   `f=0` component would read a rail trip 1 may have rotated". Leaving the
   `cqrt_alloc_i32(7)` INSIDE the body is what makes that false: every trip's
   `f=0` component reads a FRESH |7>, exactly as the twin's second block does.
   The golden shows one `cqrt_alloc_i32(7)` + one `cqrt_ry_i32_controlled` per
   trip and no free — `Ry(θ)|0>` is not `|0>` and the prepped register is
   measured, so the user owns it (Rule 6).

   Twin: slice_control_stateprep_bool_loop_iterlocal_unrolled.expected.log. */

#ifndef CQ_K
#define CQ_K 2
#endif

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = 7;
        if (b) { r = 7; cq_theta(&r, 0.2); }
        s += cq_measure(r);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
