__attribute__((noinline)) static int clamp_scale(int v, int lo, int hi, int s) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v * s;
}
int early_return(int x0, double th, int lo, int hi, int s) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(clamp_scale(x, lo, hi, s));
}
