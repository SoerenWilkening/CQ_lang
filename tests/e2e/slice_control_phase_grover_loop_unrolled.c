/* slice_control_phase_grover_loop_unrolled.c — the HAND-UNROLLED twin of
   slice_control_phase_grover_loop.c (bd test_C_libtooling-3qlq Increment 1,
   PRD §6.5). Same body, three times, no loop.

   Its golden must be BYTE-IDENTICAL to the rolled slice's; the ctest gate is
   `e2e-phase-grover-loop-twin-identical` (a `cmp` over two committed goldens —
   no clang, no opt, no plugin).

   Do NOT "simplify" this into a shared header with the loop slice: the whole
   value is that the two files reach the pass through DIFFERENT `clang -O1`
   output — a rotated loop with a header phi and two in-body diamonds on one
   side, straight-line code with six diamonds on the other — and converge on one
   gate stream. Sharing the source would test nothing.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P1 ×6 (flat). */

#define CQ_PI 3.14159265358979323846

#define CQ_PHASE_GROVER_ITER             \
    q = cq_theta(q, 0.3);                \
    if (q == 5) cq_phi(CQ_PI);           \
    q = cq_theta(q, 0.3);                \
    if (q == 0) cq_phi(CQ_PI);

int slice(void) {
    int q = 0;

    CQ_PHASE_GROVER_ITER
    CQ_PHASE_GROVER_ITER
    CQ_PHASE_GROVER_ITER

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
