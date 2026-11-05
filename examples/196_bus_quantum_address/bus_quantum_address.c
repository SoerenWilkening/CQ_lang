/* One bus: a store and a load at an ADDRESS RAIL (the run-time base + 4 * index, computed by templates). */
int bus_quantum_address(unsigned k0, double tk, unsigned j0, double tj, int x0, double tx) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned j = j0;
    cq_theta(&j, tj);
    int x = x0;
    cq_theta(&x, tx);
    int a[4] = {1, 2, 3, 4};                  /* a bus-resident alloca; the initializer is a 16-byte copy */
    a[k & 3] = x;                             /* a kept store at an address rail */
    int r = a[j & 3];                         /* a load at another address rail */
    return cq_measure(r);
}
