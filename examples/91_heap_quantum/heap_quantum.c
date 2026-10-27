#include <stdlib.h>
int heap_quantum_size(unsigned char n0, double tn, unsigned k0, double tk, unsigned char v) {
    unsigned char n = n0;
    cq_theta(&n, tn);                         /* quantum size */
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned char *a = malloc(n & 3);         /* size in [0, 3]: the block is allocated at the bound, 3 cells */
    a[k & 3] = v;                             /* store at a quantum index */
    a = realloc(a, 6);                        /* classical new size: same object, base and size updated */
    a[5] = 1;
    unsigned char r = a[1] + a[5];
    if (k > 100)
        free(a);                              /* free under a quantum condition */
    return cq_measure(r);
}
int heap_in_loop(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char *last = 0;
    for (unsigned i = 0; i < (x & 3); i++) {  /* quantum trip count */
        unsigned char *p = malloc(1);         /* one object per (site, trip) */
        p[0] = (unsigned char)(x + i);
        last = p;                             /* a pointer whose object is quantum */
    }
    return cq_measure(last ? last[0] : 7);
}
