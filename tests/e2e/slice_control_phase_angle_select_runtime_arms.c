/* slice_control_phase_angle_select_runtime_arms.c — bd test_C_libtooling-3qlq
   Increment 1 (PRD §6.5, §3, owner question Q3 ASSUMED ANSWERED "admitted"):
   the if/else phase with RUN-TIME angle arms.

   SOURCE INTENT:
       int slice(double A, double B) { ... if (q == 5) cq_phi(A); else cq_phi(B); }

   THIS IS THE SLICE THAT SEPARATES THE TWO STEMS, and it is the reason the pair
   exists. For the Ry stem a run-time arm is a CONFIRMED silent miscompile and
   DECLINES (drbq 2b clearance blocker F-11, owner option (2)): 2b lowered an
   angle select BY DIFFERENCE, so it had to compute `fl(A-B)` — whose error is
   unbounded in absolute radians (measured 0.858 rad from plain C, `Ry(PI)`
   realized as `Ry(4.0)`) and which can be `inf`/`NaN` from two FINITE arms.

   The Rz kickback computes NOTHING from the angles: it emits `x(f); rz_i1(f, B);
   x(f); rz_i1(f, A)` and hands A and B to the runtime verbatim. There is no
   subtraction, so there is no rounding class, so a run-time arm is admissible —
   PRD §3, and owner question Q3 in §12, which this session proceeds on as
   ANSWERED "admitted for the Rz stem". If that assumption is ever reversed this
   slice becomes a DECLINE fixture and its `.expected.log` is deleted; nothing
   else in the pair moves.

   The angles come in as function parameters from `main` (an argc-derived value,
   so no constant folding can reach them) and the runtime is trace-only, so the
   trace is deterministic.

   EXPECTED TRACE SHAPE: identical to slice_control_phase_angle_select.c with the
   two literal angles replaced by whatever `main` passed. No fsub in the lowered IR.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq taint escape: tainted value consumed by an unknown callee`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P2, run-time arms ADMITTED (Rz only). */

__attribute__((noinline))
int slice(double A, double B) {
    int q = 0;
    q = cq_theta(q, 0.5);

    if (q == 5) cq_phi(A);
    else        cq_phi(B);

    return cq_measure(q);
}
int main(int argc, char **argv) { (void) argv; (void) slice(0.9 * argc, 0.3 * argc); return 0; }
