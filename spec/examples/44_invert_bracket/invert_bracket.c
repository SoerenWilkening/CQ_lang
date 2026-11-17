int invert_bracket(int x0, double th, int c, int k, double phi) {
    int x = x0;
    cq_theta(&x, th);
    cq_invert_begin();
    int y = x * c;
    if (y == k)
        cq_phi(phi);
    cq_invert_end();
    return cq_measure(x);
}
