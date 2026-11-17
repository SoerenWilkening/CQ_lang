/* One bus: a pointer is an integer. It is stored in a cell, loaded at an address rail, and is the next address. */
int bus_pointer_cell(unsigned k0, double tk, int x0, double tx, int v) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    int a = 1, b = x;
    int *slot[2] = { &a, &b };                /* two addresses stored in cells */
    int *p = slot[k & 1];                     /* loaded at an address rail: p is a 64-bit address rail */
    *p = v;                                   /* a kept store through the loaded pointer */
    int **pp = &slot[(k >> 1) & 1];
    **pp += 3;                                /* the in-place form at the address rail *pp; the copy of *pp is kept */
    return cq_measure(a + b);
}
