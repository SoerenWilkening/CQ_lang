int nonreconverging_returns(int x0, double th, int k, int r0, double t1, double t2) {
    int x = x0;
    cq_theta(&x, th);
    int r = r0;
    if (x > k) {
        cq_theta(&r, t1);                  /* r is rotated and never measured in either arm */
        return cq_measure(x);
    }
    cq_theta(&r, t2);
    return cq_measure(x) + 1;              /* two return arms, no common merge */
}
