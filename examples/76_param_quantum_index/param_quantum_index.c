int param_bounded(unsigned x0, double th, const int *t, unsigned n) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(t[x % n]);
}
int param_unbounded(unsigned char x0, double th, const int *t) {
    unsigned char x = x0;
    cq_theta(&x, th);
    return cq_measure(t[x]);
}
