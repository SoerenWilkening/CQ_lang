/* slice_control_inplace_ry_loop_leading_gate_unrolled.c — the HAND-UNROLLED TWIN
   of slice_control_inplace_ry_loop_leading_gate.c (ctest
   `e2e-inplace-ry-loop-leading-gate-twin-identical`). */
int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_phi(q, 0.1);

    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_phi(q, 0.1);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
