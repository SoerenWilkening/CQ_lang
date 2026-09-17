/* slice_control_inplace_ry_inloop_hoisted_cond_twin.c — the HAND-UNROLLED TWIN of
   `slice_control_inplace_ry_inloop_hoisted_cond.c` (bd `test_C_libtooling-drbq.12`,
   2026-09-17). The two goldens are compared byte-for-byte by
   `e2e-inloop-hoisted-cond-twin-identical`; that equality is the witness, and this
   file exists only to carry it.

   THE TWIN IS NOT A SECOND PROGRAM, it is the SAME program with the loop written out
   — and it is a customer of the SAME over-decline for a DIFFERENT reason, which is
   why the pair is worth having. In the rolled form `clang -O1` LICM-hoists the
   invariant compare into the preheader, so the region's `Pred` (the loop header) is
   not the compare's block. In this flat form there is no loop at all: `-O1` CSEs the
   two `q == 5` compares into ONE in the entry block, so region 1's `Pred` IS the
   compare's block (it always passed P4) while region 2's `Pred` is region 1's MERGE
   block. Cyclic and acyclic, one fence. PRD §13.2 row W's sixteen twin-matrix cells
   were `DECLINE-BOTH` for exactly this reason, and both halves move together.

   ⚠ READ THE EQUALITY FOR WHAT IT IS. Byte identity of the two traces says the rolled
   lowering emits the same gate sequence the hand-unrolled one does — it does NOT by
   itself say either is the right unitary (Rule 2; owner ruling S3 of 2026-09-17:
   "correctness, not identity, is the claim"). The correctness argument is in the
   subject slice's header and in
   `ir-pass/test/control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll`. What
   this gate uniquely catches is a rolled/flat DIVERGENCE — a different circuit from
   one source — which no single golden can see.

   Every token outside the loop/unroll is identical to the subject's on purpose. */
int slice(void) {
    int q = 0;
    int r = 0;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.3);
    if (q == 5) { r = cq_theta(r, 0.9); }   /* trip 1 */
    if (q == 5) { r = cq_theta(r, 0.9); }   /* trip 2 */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
