/* Rule 2 + rule 8: a measurement inside a quantum arm. The measurement of y is executed unconditionally (a measurement
 * is never conditioned on quantum data; the flag is never measured), so m = F ? outcome : c is first a quantum select;
 * once x is measured, F and m depend only on measured values and collapse to classical (rule 2): a plain int returns. */
int measure_in_arm(int x0, double tx, int y0, double ty, int k, int c) {
    int x = x0, y = y0, m = c;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    if (x > k) m = cq_measure(y);
    return m + cq_measure(x);
}
