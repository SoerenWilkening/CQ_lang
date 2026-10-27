/* Rule 14 + rules 8, 10: a K-loop body with a phase arm and a controlled rotation: the phase kicks back on
 * a_j & (x & 1), the rotation of r is controlled on a_j. */
int phase_in_kloop(unsigned x0, double tx, unsigned k, double p, double t) {
    unsigned x = x0;
    int r = 0;
    cq_theta(&x, tx);
    while (x > k) {           /* [K] */
        if (x & 1) cq_phi(p);
        cq_theta(&r, t);
        x >>= 1;
    }
    return cq_measure(r) + cq_measure(x);
}
