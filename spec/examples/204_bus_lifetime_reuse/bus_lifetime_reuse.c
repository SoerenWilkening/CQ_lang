/* One bus: lifetime markers are dropped. A block-scoped object is ONE block for all trips; a recursion has one per activation. */
int bus_scope_reuse(unsigned k0, double tk, int x0, double tx, int n) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    int s = 0;
    for (int i = 0; i < n; i++) {
        int a[2];                             /* one block for all trips: a[1] is never initialized */
        a[0] = i;                             /* displaces what the trip before left in a[0] */
        a[(k >> i) & 1] = x;                  /* a kept store at an address rail */
        s += a[0] + a[1];                     /* a[1]: 0 (never written), this trip's x, or the x a trip before left */
    }
    return cq_measure(s);
}
__attribute__((noinline)) static int walk(unsigned k, int x, int d) {
    int a[2] = {d, 0};                        /* one block per activation */
    a[k & 1] = x;
    int below = d ? walk(k >> 1, x, d - 1) : 0;   /* classical depth: ordinary calls of the clone */
    return a[0] + below;                      /* loaded after the inner activation returned */
}
int bus_recursion(unsigned k0, double tk, int x0, double tx, int d) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    return cq_measure(walk(k, x, d));
}
