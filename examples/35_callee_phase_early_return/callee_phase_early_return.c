__attribute__((noinline)) static int guard(int v, int lo, int s, double p) {
    if (v < lo) {
        cq_phi(p);
        return lo;
    }
    return v * s;
}
int callee_phase_early_return(int x0, double th, int lo, int s, double p) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(guard(x, lo, s, p));
}
