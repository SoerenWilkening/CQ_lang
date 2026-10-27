int invert_theta(int x0, double th, double t2) {
    int x = x0;
    cq_theta(&x, th);
    cq_invert_begin();
    cq_theta(&x, t2);
    cq_invert_end();
    return cq_measure(x);
}
__attribute__((noinline)) static void prep(unsigned *x, unsigned y, double t1, double t2, unsigned k) {
    cq_theta(x, t1);
    if (y > k)
        cq_theta(x, t2);
}
int invert_call(unsigned x0, unsigned y0, double ty, double t1, double t2, unsigned k) {
    unsigned x = x0, y = y0;
    cq_theta(&y, ty);
    prep(&x, y, t1, t2, k);
    cq_invert_begin();
    prep(&x, y, t1, t2, k);
    cq_invert_end();
    return cq_measure(x) + cq_measure(y);
}
