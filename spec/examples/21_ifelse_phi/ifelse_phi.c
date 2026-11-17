int ifelse_phi(int x0, double th, int k, int c, int s, double p1, double p2) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (x > k) {
        cq_phi(p1);
        r = x + c;
    } else {
        cq_phi(p2);
        r = x * s;
    }
    return cq_measure(r);
}
