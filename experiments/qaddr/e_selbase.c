#include <stdint.h>
/* a select arm that is a pointer below its object (made through an integer), accessed at an offset back inside. */
static long A[64], B[64];
int main(void) {
    for (int i = 0; i < 64; i++) { A[i] = i + 1; B[i] = 100 - i; }
    unsigned char q = 7; cq_theta(&q, 0.0);
    long *x = (long *)((uintptr_t)A - 64);
    long *p = (q & 1) ? x : B;
    return (int)cq_measure(p[8 + (q >> 1 & 3)] & 127);
}
