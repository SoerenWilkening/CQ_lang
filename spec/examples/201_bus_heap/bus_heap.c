#include <stdlib.h>
/* One bus: malloc is __cq_alloc, realloc a new block and a byte copy of min(old size, new size), free is nothing. */
int bus_heap(unsigned k0, double tk, int x0, double tx) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    int *a = malloc(4 * sizeof(int));
    a[k & 3] = x;                             /* a kept store at an address rail inside the block */
    a = realloc(a, 8 * sizeof(int));          /* the old size is loaded from the 8 bytes before the block */
    a[7] = 2;
    int r = a[k & 7];                         /* a load at an address rail inside the new block */
    free(a);                                  /* nothing */
    return cq_measure(r);
}
