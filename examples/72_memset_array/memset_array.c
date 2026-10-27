#include <string.h>
int memset_over_quantum(unsigned x0, double th, int c, int k) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[4];
    for (int i = 0; i < 4; i++) a[i] = x + i;   /* cells hold quantum values */
    int before = a[k & 3];                      /* read one before the reset */
    memset(a, 0, sizeof a);                     /* reset: every cell back to 0 */
    a[x & 3] = c;                               /* quantum-index write after the reset */
    return cq_measure(before + a[1]);
}
int memset_quantum_byte(unsigned x0, unsigned y0, double tx, double ty) {
    unsigned x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    unsigned char b[4];
    memset(b, (int)x, sizeof b);                /* fill byte is quantum */
    b[y & 3] = 7;                               /* quantum-index write keeps the array in memory */
    return cq_measure(b[0] + b[3]);
}
