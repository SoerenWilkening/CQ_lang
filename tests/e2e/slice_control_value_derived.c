/* slice_control_value_derived.c — e2e smoke for a value diamond over a DERIVED
   base (a pre-region IN-PLACE rotation on the value register; the 9hh
   discipline) under the Inc-2 controlled-copy merge.

   ⚠ RE-SPELLED AT THE INC-2 REBASE ONTO THE LANDED INC 1 (2026-09-06). The
   derivation used to be `p = cq_phi(p, 0.9)` — a pre-region DIAGONAL alias of
   p's wire. `cq_phi` is REGISTER-FREE since Inc 1 (`void cq_phi(double)`,
   decisions D1/D2), so that line is now a HARD COMPILE ERROR ("too many
   arguments to function call, expected single argument 'angle'") and the slice
   did not build. Two repairs were MEASURED before choosing:
     (a) delete the line  -> the program becomes BYTE-IDENTICAL to
         slice_control_value_diamond.c and its trace byte-identical to that
         slice's golden: a duplicate, i.e. a coverage claim with no coverage
         (the Inc-1 OQ-5 precedent, where slice_loop_break_qq_phase was DELETED
         for exactly this).
     (b) `p = cq_theta(p, 0.9)` -> a pre-region in-place Ry on the SAME handle.
         Kept. It preserves what the slice is for and is not a new accept class:
         MEASURED rc=0 on the pre-3qlq oracle 52d7764 (29 trace lines, the swap
         ROUTE), rc=0 on the landed Inc-1 `main` (29 lines, the route) and rc=0
         here (24 lines, the MERGE) — the plain diamond's 23 lines plus ONE
         unconditional `cqrt_ry_i32` on the value handle, strictly before the
         hoisted chain. STRICT stage 2b (`free_pairing_check.py`, no
         --allow-unproven) rc=0 on all three.
   The rotation is Ry, not Rz, so read the old "diagonal alias" wording as
   history: what the emitter sees is unchanged (rotation lowering RAUWs the
   pre- and post-rotation SSA names to the SAME i32 handle), which is the
   property this slice exists to exercise — get the straight-through operand of
   the merge wrong and the second controlled copy names the wrong register.

   ⚠ NO TWIN AND NO `cmp` GATE, deliberately (bd test_C_libtooling-3qlq Inc 2,
   Rule-13 round-1 review finding F-V2-2). MEASURED at the rebase by writing the
   twin (`int t = R(p); p = (q>5) ? t : p;` after the same pre-region rotation):
   it DECLINES `cq controlled lowering: control flow under quantum control` on
   the rebased binary, exactly as the old `cq_phi`-derived twin declined on the
   oracle and on the Inc-2 branch. `SelectClassify` conservatively refuses a
   coherent ROTATION-lineage select OPERAND, while the `br`-value classifier
   deliberately ACCEPTS a derived base. Inc 2 reuses the select EMITTER, not the
   select CLASSIFIER, so the two dispositions differ BY DESIGN and a
   byte-identity gate here would assert something false (the drbq Inc-4 "no
   `cmp` twin gate, deliberately" precedent). The third twin pair is `mixedops`.

   ⚠ AND THAT MEASUREMENT ANSWERS AN OPEN QUESTION IN THE WRONG DIRECTION.
   OWNER_QUESTIONS.md's Inc-2 REVIEW FLAG reads "after Inc 1 there is NO Rz
   lineage any more (cq_phi is register-free), so this class must be re-asked
   post-rebase". Re-asked, and MEASURED: the class is NOT dissolved — it
   re-appears with `cq_theta` as the derivation, and this slice is still the ONE
   accept in the value family that reaches `emitSelectRegion` with an input its
   own classifier would refuse. It still wants a Rule-13 lens of its own.
   STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);
    p = cq_theta(p, 0.25);
    p = cq_theta(p, 0.9);          /* DERIVED base — in-place Ry on p's wire */
    if (q > 5) { p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2; }
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
