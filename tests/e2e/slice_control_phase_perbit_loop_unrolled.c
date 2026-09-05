/* slice_control_phase_perbit_loop_unrolled.c — the HAND-UNROLLED twin of
   slice_control_phase_perbit_loop.c (bd test_C_libtooling-3qlq Increment 1,
   PRD §6.5, D4). K = 4 written out, no loop.

   Its golden must be BYTE-IDENTICAL to the rolled slice's; the ctest gate is
   `e2e-phase-perbit-loop-twin-identical`. Do NOT share a header with the rolled
   slice — the value is that the two files reach the pass through different
   `clang -O1` output and converge on one gate stream.

   NOTE the shift amounts are LITERALS here and the induction variable there.
   That is the point of the pair: if the rolled form's `lshr` picked up the
   header phi instead of the trip's value, or if `collapseFlattenedLoopRails`
   re-anchored the wrong rail, the two streams diverge and this `cmp` says so.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P1 ×4 (flat). */

int slice(void) {
    int q = 0;
    q = cq_theta(q, 0.5);

    if ((q >> 0) & 1) cq_phi(0.3);
    if ((q >> 1) & 1) cq_phi(0.3);
    if ((q >> 2) & 1) cq_phi(0.3);
    if ((q >> 3) & 1) cq_phi(0.3);

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
