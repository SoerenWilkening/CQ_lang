#include <string.h>
int memcpy_classical(unsigned x0, double th, const int *src) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[4];
    memcpy(a, src, sizeof a);                   /* classical data into the local array */
    a[x & 3] += 1;                              /* quantum-index read-modify-write: every cell becomes quantum */
    return cq_measure(a[0] + a[3]);
}
int memcpy_quantum(unsigned x0, unsigned y0, double tx, double ty, int c) {
    unsigned x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    int a[4], b[4];
    for (int i = 0; i < 4; i++) a[i] = x + i;   /* cells hold quantum values */
    memcpy(b, a, sizeof b);                     /* copy of an array of quantum cells */
    b[y & 3] = c;                               /* quantum-index write into the copy */
    return cq_measure(a[1] + b[1]);
}
