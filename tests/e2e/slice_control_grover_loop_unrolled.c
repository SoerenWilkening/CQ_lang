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
/* slice_control_grover_loop_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop.c (bd test_C_libtooling-8h7d.5).

   Character for character the same body, written out twice with no loop. It
   exists for ONE reason: its golden must be byte-identical to the rolled form's,
   and a twin that lives in the tree is a twin that gets re-measured on every
   run. The `cmp` is a ctest entry (e2e-grover-loop-twin-identical), not a comment.

   Do NOT "simplify" this into a shared header with the loop slice: the whole
   value is that the two files reach the pass through DIFFERENT `clang -O1`
   output — a rotated loop with two header phis and two in-body diamonds on one
   side, straight-line code with four diamonds on the other — and converge on one
   gate stream. Sharing the source would test nothing. */

#define CQ_PI 3.14159265358979323846

#define CQ_GROVER_ITER                       \
    if (q == 5) { cq_phi(CQ_PI); }           \
    q = cq_theta(q, -0.5);                   \
    if (q == 0) { cq_phi(CQ_PI); }           \
    q = cq_theta(q, 0.5);

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);

    CQ_GROVER_ITER
    CQ_GROVER_ITER

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
