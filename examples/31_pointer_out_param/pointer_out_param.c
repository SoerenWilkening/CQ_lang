__attribute__((noinline)) static int split(int v, int k, int *hi) {
    *hi = v >> k;
    return v & ((1 << k) - 1);
}
int pointer_out_param(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int hi;
    int lo = split(x, k, &hi);
    return cq_measure(lo + hi);
}
