int invert_controlled_loop(int x0, double tx, int r0, const double *th, int n, int k, double ph) {
    int x = x0;
    cq_theta(&x, tx);
    int r = r0;
    cq_invert_begin();
    for (int i = 0; i < n; i++) {                   /* classical bound */
        if (x > k + i) {                            /* quantum condition, different per trip */
            cq_theta(&r, th[i]);                    /* controlled Ry on r */
            cq_phi(ph);                             /* branch phase: kickback on the flag */
        }
    }
    cq_invert_end();
    return cq_measure(r) + cq_measure(x);
}
