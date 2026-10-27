int prep_const_incoming(int x0, double th, int k, double t) {
    int x = x0;
    cq_theta(&x, th);
    int r = 7;                             /* the straight-through value is not the prep seed */
    if (x == k) { r = 0; cq_theta(&r, t); }
    return cq_measure(r) + cq_measure(x);
}
int prep_beside_phase(int x0, double th, int k, int r0, double t, double p) {
    int x = x0;
    cq_theta(&x, th);
    int r = r0;
    if (x > k) { r = 0; cq_theta(&r, t); } /* a fresh prep in one arm */
    else cq_phi(p);                        /* a phase in the other */
    return cq_measure(r) + cq_measure(x);
}
int prep_twice(int x0, double th, int k1, int k2, int r0, double t1, double t2) {
    int x = x0;
    cq_theta(&x, th);
    int r = r0;
    if (x > k1) { r = 0; cq_theta(&r, t1); }
    if (x < k2) { r = 0; cq_theta(&r, t2); } /* overwrites a register that may already be prepared */
    return cq_measure(r) + cq_measure(x);
}
