/* slice_control_inplace_ry_bool_loop.c — bd `test_C_libtooling-wx8g` (l4x4.c),
   THE HEADLINE CUSTOMER: an in-place controlled-Ry arm on a bare `_Bool`
   condition, ROLLED in a classically-bounded loop.

       bool b = cq_theta(0, .5);
       int  r = cq_theta(7, .25);
       for (k < K) if (b) r = cq_theta(r, .2);

   `b` is loop-INVARIANT and `r` is loop-CARRIED, so R7-loop clauses (b)/(b')
   own it: `r`'s header phi peels to the classical-arg-0 mint `cq_theta(7,.25)`
   dominating the header, which is exactly what round 2's `collapseRailPhisIn`
   will claim.

   ⚠ THIS PROGRAM COMPILED IN NO SPELLING ON ANY BINARY UNTIL 2026-09-14, and
   the sentence is `CLAUDE.md`'s, not this file's: the rail spelling was carved
   out by l4x4.b (`ArmClassify`'s `RailCond && Region.InLoop` decline, now
   retired) and the COMPARE spelling cannot express it at all — `-O1` LICM-hoists
   a loop-invariant compare and `condWireDisposition`'s P4 prong refuses a
   cross-block condition (row W; measured again 2026-09-14 on the ORACLE, probe
   `w_c_compare_invariant`, `condition predates a non-diagonal gate`).

   THE WITNESS IS THE TWIN. This golden must be BYTE-IDENTICAL to
   slice_control_inplace_ry_bool_loop_unrolled.expected.log (ctest
   `e2e-inplace-ry-bool-loop-twin-identical`). Its blind spot is quoted with it,
   as the drbq Inc-3 pairs quote theirs: the unrolled side IS l4x4.b's flat
   lowering, so a defect the two paths SHARE is invisible here; the flat side's
   own witness is the l4x4.b lit family.

   NOTHING IS MINTED, STRIPPED OR FREED FOR THE CONDITION — the register IS the
   flag (`emitInPlaceRotationRegion` step 1 for a rail; steps 3's strip+free are
   skipped whole). Both registers are LEFT ALLOCATED: `Ry(θ)|0⟩ ≠ |0⟩` for `b`
   and Increment 1's structural freeze keeps the spine off `r`. That is Rule 6's
   sanctioned fallback and is identical in the twin. Stage 2b STRICT reports
   `4 rail mint(s) of which 4 left allocated, 0 cqrt_free site(s)`.

   K-INDEPENDENCE IS A MEASUREMENT, NOT A GATE (the 8h7d.5 / drbq Inc-3
   precedent) — see the CMakeLists note for the measured line counts. */

#ifndef CQ_K
#define CQ_K 2
#endif

int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);
    for (int k = 0; k < CQ_K; ++k) {
        if (b) r = cq_theta(r, 0.2);
    }
    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
