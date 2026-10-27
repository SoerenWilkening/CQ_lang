__attribute__((noinline)) static int f(int v, int c) {
    int s = v * v;
    return s + c;
}

int call_result_uncomputed(int x0, double th, int c, int k, double phi) {
    int x = x0;
    cq_theta(&x, th);
    if (f(x, c) == k)
        cq_phi(phi);
    return cq_measure(x);
}
