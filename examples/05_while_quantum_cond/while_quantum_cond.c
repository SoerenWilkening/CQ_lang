int while_quantum_cond(unsigned x0, double th, unsigned k, unsigned a, unsigned b) {
    unsigned x = x0;
    cq_theta(&x, th);
    int n = 0;
    while (x > k) {
        x = x * a + b;
        n++;
    }
    return cq_measure(n);
}
