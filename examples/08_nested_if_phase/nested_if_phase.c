int nested_if_phase(int x0, double th, int k1, int k2, double p1, double p2) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k1) {
        cq_phi(p1);
        if (x < k2)
            cq_phi(p2);
    }
    return cq_measure(x);
}
