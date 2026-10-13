/* slice_control_phase_angle_select.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5, §3 "Angle select"): the if/else phase, CONSTANT arms.

   SOURCE INTENT:
       if (q == 5) cq_phi(0.9); else cq_phi(0.3);

   `clang -O1` never hands that to the pass as a diamond: SimplifyCFG sinks the
   two calls into ONE call on `select i1 %c, double 0.9, double 0.3` (measured,
   PRD §6.1). The Rz stem's lowering is then EXACT and performs NO SUBTRACTION:

       x(f); cqrt_rz_i1(f, 0.3); x(f); cqrt_rz_i1(f, 0.9)

   — P(0.9) when the flag is 1, P(0.3) when it is 0. THIS RETIRES THE 2b
   BY-DIFFERENCE FORM FOR THE Rz STEM, and with it the `2^-40` rounding fence:
   2b had to synthesize `fl(A-B)`, an `fsub` the source never wrote whose error is
   unbounded in absolute radians; the kickback form never realizes a difference
   at all. (The Ry stem followed in bd dm7f.6: the X-bracket form, run-time arms
   admitted, the bound retired.)

   EXPECTED TRACE SHAPE: ONE mint, cqrt_x(f), cqrt_rz_i1(f, 0.3), cqrt_x(f),
   cqrt_rz_i1(f, 0.9), ONE strip, ONE free. No cswap, no `_controlled`, no fsub
   anywhere in the lowered IR.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq taint escape: tainted value consumed by an unknown callee`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P2 (angle select). */

int slice(void) {
    int q = 0;
    cq_theta(&q, 0.5);

    if (q == 5) cq_phi(0.9);
    else        cq_phi(0.3);

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
