/* slice_control_grover_loop_offset_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_offset.c (bd test_C_libtooling-8h7d.5).

   Same body, twice, no loop, so the in-place `cqrt_addc_i32` stream it produces
   is the one round 1 / the straight-line M-C fence already ship. The `cmp`
   against the rolled golden is ctest entry e2e-grover-loop-offset-twin-identical. */

#define CQ_PI 3.14159265358979323846

volatile int cq_off = 3;

#define CQ_OFFSET_ITER                       \
    if (q == 5) { q = cq_phi(q, CQ_PI); }    \
    q = cq_theta(q, -0.5);                   \
    q += cq_off;                             \
    q = cq_theta(q, 0.5);

int slice(void) {
    int q = 0;

    q = cq_theta(q, 0.5);
    q += cq_off;

    CQ_OFFSET_ITER
    CQ_OFFSET_ITER

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
