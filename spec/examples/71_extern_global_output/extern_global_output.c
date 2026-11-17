int signflag;                                            /* external linkage: visible to other translation units */
__attribute__((noinline)) static int body(int v, int k, int *sgn) {
    *sgn = (v < k) ? -1 : 1;                             /* quantum-derived sign through the pointer */
    return v * v;
}
int extern_global_output(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r = body(x, k, &signflag);                       /* the lgamma shape: lgamma_r(x, &signgam) */
    return cq_measure(r);
}
