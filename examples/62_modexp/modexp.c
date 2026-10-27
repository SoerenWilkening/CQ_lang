int modexp(unsigned e0, double th, unsigned a, unsigned N, int nbits) {
    unsigned e = e0;
    cq_theta(&e, th);
    unsigned r = 1, base = a % N;
    for (int i = 0; i < nbits; i++) {
        if ((e >> i) & 1)
            r = (r * base) % N;
        base = (base * base) % N;
    }
    int m = cq_measure(r);
    return m + cq_measure(e);
}
