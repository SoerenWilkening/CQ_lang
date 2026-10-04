/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose is left verbatim rather than silently corrected; read it with this.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_grover_loop_dynamic.c — bd test_C_libtooling-8h7d.5: the ROLLED
   property, demonstrated the only way that cannot be faked.

   The trip count is a `volatile` global, so the compiler CANNOT know it: no
   unroll is possible even in principle, and the emitted IR must contain exactly
   ONE copy of the per-iteration gate stream (PRD 7.3 §2.1 — IR size independent
   of the trip count; only the runtime trace grows). The other loop slices in this
   directory use a literal `2` because they are byte-diffed against hand-unrolled
   twins; this one exists so "rolled" is a measured property and not an inference
   from a small constant.

   `cq_n` is 3, so the trace is three iterations long and stays readable. Set it to
   3000 and the golden would be 3000x longer while the LOWERED IR IS UNCHANGED —
   that is the claim.

   The dynamic bound also puts a different shape in front of the pass (Rule 9):
   `clang -O1` emits a rotated loop with a zero-trip GUARD branch, so the loop has
   no dedicated preheader and the register's header phi takes its external
   incoming from the guard block. `collapseFlattenedLoopRails` identifies that
   edge as "the incoming that is not from the latch and not inside the loop",
   which is why the guard shape needs no special case.

   STRICT stage 2b. */

#define CQ_PI 3.14159265358979323846

volatile int cq_n = 3;

int slice(void) {
    int q = 0;

    cq_theta(&q, 0.5);

    for (int i = 0; i < cq_n; ++i) {
        if (q == 5) {
            cq_phi(CQ_PI);
        }
        cq_theta(&q, -0.5);
        if (q == 0) {
            cq_phi(CQ_PI);
        }
        cq_theta(&q, 0.5);
    }

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
