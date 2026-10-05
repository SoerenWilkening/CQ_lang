/* slice_control_phase_perbit_loop_k32.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5, D4): THE K-INDEPENDENCE WITNESS. The same per-bit idiom as
   slice_control_phase_perbit_loop.c with K = 32 instead of 4, ROLLED ONLY —
   there is deliberately NO unrolled twin, because a 32-times hand expansion
   would prove nothing this pair does not.

   WHAT IT WITNESSES. D4 rests on the lowered IR being independent of the trip
   count: if the per-bit loop unrolled, "the classical loop is the idiom" would
   be a promise of 32× IR growth for a 32-bit register, and the deleted multi-bit
   `cqrt_rz_<W>` would have been a real capability loss rather than a
   redundancy. The measurement is a LINE COUNT of stage-2 IR at K=4 vs K=32,
   which is a measurement and not a ctest gate (the 8h7d.5 precedent for
   `slice_control_grover_loop_dynamic`); this slice is the artifact it is taken
   on, and its golden is 32 trips of the same nine-line region.

   GOLDEN TRACE SHAPE: 32 × (and_hl, icmp mint, x, cqrt_rz_i1(f, 0.3), x,
   strip, and_hl_unc, two cqrt_free). ONE copy in the lowered IR.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P6. */

#define CQ_W 32

int slice(void) {
    int q = 0;
    cq_theta(&q, 0.5);

    for (int i = 0; i < CQ_W; ++i)
        if ((q >> i) & 1) cq_phi(0.3);

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
