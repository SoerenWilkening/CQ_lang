/* Rule 14: two nested K-loops inside a quantum value arm. The outer chain is seeded by the arm flag, the inner chain
 * by the outer trip predicate; the arm merges by select. */
int nested_kloops_in_arm(unsigned x0, double tx, unsigned y0, double ty, unsigned k, unsigned c) {
    unsigned x = x0, y = y0, s = 0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    if (x > c) {
        while (x > k) {           /* [K] */
            unsigned z = y;
            while (z > k) {       /* [K] */
                s += z;
                z >>= 1;
            }
            x -= 1;
        }
    } else {
        s = x + y;
    }
    return cq_measure(s);
}
