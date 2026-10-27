/* Rule 6 witness: a value arm updates a SUPERPOSED register, then the register is rotated again.
 * y' = y + [x > k] is a bijection in y, so the old y rail is cleaned (compute y back from y', copy, uncompute)
 * before the second rotation; otherwise the leftover record would dephase y. */
int value_arm_then_rotate(int x0, double tx, int y0, double ty, int k, double t) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    if (x > k) y += 1;
    cq_theta(&y, t);
    return cq_measure(y) + cq_measure(x);
}
