int mixed_phase_value_arm(int x0, double tx, int y0, double ty, int k, int r0, double a, double b, double t) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    int r = r0;
    if (x > k) {
        cq_phi(a);            /* phase arm: kickback on the flag */
        y += 1;               /* value arm: merge into a fresh rail */
        cq_theta(&r, t);      /* in-place controlled Ry on r */
    } else {
        cq_phi(b);            /* phase under the negated flag */
    }
    return cq_measure(y) + cq_measure(r) + cq_measure(x);
}
