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
    if (q == 5) { q = cq_phi(q, CQ_PI); }    \
    q = cq_theta(q, -0.5);                   \
    if (q == 0) { q = cq_phi(q, CQ_PI); }    \
    q = cq_theta(q, 0.5);

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);

    CQ_GROVER_ITER
    CQ_GROVER_ITER

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
