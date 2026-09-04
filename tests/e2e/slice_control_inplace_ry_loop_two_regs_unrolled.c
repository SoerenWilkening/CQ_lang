/* slice_control_inplace_ry_loop_two_regs_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_loop_two_regs.c (ctest
   `e2e-inplace-ry-loop-two-regs-twin-identical`). */
int slice(void) {
    int q = 0;
    int r = 7;
    int s = 9;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    s = cq_theta(s, 0.125);

    if (q == 5) { r = cq_theta(r, 0.9); }
    if (q == 3) { s = cq_theta(s, 0.7); }
    q = cq_phi(q, 0.1);

    if (q == 5) { r = cq_theta(r, 0.9); }
    if (q == 3) { s = cq_theta(s, 0.7); }
    q = cq_phi(q, 0.1);

    return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
