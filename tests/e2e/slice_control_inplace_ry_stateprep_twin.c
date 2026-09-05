/* slice_control_inplace_ry_stateprep_twin.c — THE WITNESS for Inc 4's state-prep
   accept: the manual CHAINED spelling of the same circuit, which the PRE-INC-4
   binary already lowered (control-in-place-PRD §14.8, bd
   test_C_libtooling-drbq Inc 4).

   There is no `_unrolled` twin here (this is flat-only) and no golden can
   witness "the fresh rail holds |SEED> on the f=0 branch". So the witness is
   BYTE IDENTITY between `slice_control_inplace_ry_stateprep.expected.log` and
   the REDUCTION of THIS golden under two rewrites, each a physical identity and
   NEITHER of them the transformation under test:

     (i)  DELETE `cqrt_ry_i32(h1, 0x0p+0)` — Ry(0) = I;
     (ii) MOVE `cqrt_alloc_i32(0) -> h1` to immediately before the first
          `cqrt_ry_i32_controlled(·, h1, ·)` naming it — a fresh-rail alloc acts
          on a wire nothing else names, so it commutes with every gate that does
          not name its handle;
     (iii) renumber handles by first appearance.

   THE REDUCTION IS COMMITTED AS TWO GOLDENS, NOT AS A SCRIPT, deliberately: a
   reviewer must be able to re-derive it by hand from two files in the tree.
   (`inc4-records/reduce_twin.py` implements the three rewrites and could become
   a fourth ctest entry; recorded, not proposed. A `compare_files` gate would be
   WRONG here — the two goldens differ by a reduction, not by identity.)

   ⚠ WHAT BYTE IDENTITY PROVES AND WHAT IT DOES NOT (the
   `by-difference-twin-blind-to-arithmetic` lesson applied to this witness). It
   proves the STRUCTURE: the flag is minted from the same compare, the control
   polarity is the same, the strip and the free are the same, and the freeze
   applies to the same rail. It does NOT prove "the fresh rail starts at |SEED>".
   The witness is deliberately honest about not sharing the transformation it
   witnesses — the twin performs a REAL Ry(0) on a REAL allocated rail and Inc 4
   performs neither — so the reduction states the two facts being claimed instead
   of hiding them. */
int slice(void) {
    int q = cq_theta(3, 0.3);
    int r = cq_theta(0, 0.0);      /* the manual mint: alloc + a REAL Ry(0) = I */
    if (q == 5) {
        r = cq_theta(r, 0.9);      /* CHAINED — the Inc-1 shape, pre-Inc-4      */
    }
    return (int) cq_measure(r) + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
