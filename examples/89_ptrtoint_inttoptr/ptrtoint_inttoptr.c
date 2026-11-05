#include <stdint.h>
int ptr_roundtrip(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[2] = {1, 2}, b[2] = {3, 4};
    int *p = (x & 1) ? a : b;                 /* pointer select under a quantum flag: one 64-bit address rail */
    uintptr_t u = (uintptr_t)p;               /* ptrtoint: the address as an integer */
    u ^= (x & 4);                             /* integer arithmetic on the address */
    int *q = (int *)u;                        /* inttoptr: back to a pointer */
    return cq_measure(*q + v);
}
