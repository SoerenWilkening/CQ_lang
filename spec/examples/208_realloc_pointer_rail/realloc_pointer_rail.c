#include <stdlib.h>
/* Rule 16: realloc of a pointer rail. The old size is loaded from the block header at the address rail p - 8. */
int realloc_pointer_rail(unsigned k0, double tk, int x0, double tx) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    int *a = malloc(8), *b = malloc(16);
    a[1] = x;
    b[1] = 5;
    b[2] = 7;                                 /* beyond a's 8 bytes: copied only when p = b */
    int *p = (k & 1) ? a : b;                 /* which block is quantum: an address rail */
    int *q = realloc(p, 24);                  /* a new block, min(old size, 24) bytes copied from the address rail */
    int r1 = cq_measure(q[1]);                /* byte 4..7: copied from either block */
    return r1 + cq_measure(q[2]);             /* byte 8..11: copied only when the old size is 16 */
}
