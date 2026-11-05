#include <stdlib.h>
/* Rule 16: an allocation whose size is a rail is made at K2 bytes; the predicate n > K2 is a kept output rail. */
int malloc_rail_size(unsigned long n0, double tn, int x0, double tx, unsigned j) {
    unsigned long n = n0;
    cq_theta(&n, tn);
    int x = x0;
    cq_theta(&x, tx);
    int *a = malloc(n);                       /* a rail size */
    a[0] = x;
    int r = a[j & 1];                         /* a load at a classical run-time address */
    free(a);
    return cq_measure(r);
}
