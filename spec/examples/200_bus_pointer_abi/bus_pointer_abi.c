/* One bus: a pointer crosses a call as ONE scalar, a classical ptr (mask digit 0) or an address rail (digit 1). */
static int tab[4];
__attribute__((noinline)) static void put(int *p, int v) { *p = v; }             /* a callee that stores: no twin */
__attribute__((noinline)) static int *slot(unsigned i) { return &tab[i & 3]; }   /* a pointer result */
int bus_pointer_arg(unsigned k0, double tk, int x0, double tx) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    int a[4] = {0, 0, 0, 0};                  /* a memset of a bus-resident alloca */
    put(&a[k & 3], x);                        /* an address rail and a rail: the clone of mask 11 */
    put(&a[2], x);                            /* a classical pointer and a rail: the clone of mask 01, the ptr stays a ptr */
    put(&a[1], 5);                            /* a classical pointer and value: put's own symbol */
    return cq_measure(a[0] + a[1]);
}
int bus_pointer_result(unsigned k0, double tk, int v) {
    unsigned k = k0;
    cq_theta(&k, tk);
    *slot(k) = v;                             /* the clone returns an address rail; a kept store through it */
    return cq_measure(tab[1]);
}
