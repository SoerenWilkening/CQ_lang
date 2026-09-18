/* UNROLLED twin of rolled.c — three trips written out, i = 0,1,2. */
#include "CQ.h"
int k;
static int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int p = 0; p = cq_theta(p, 0.25);
    if (q > 5) { p += (k*0 + 7) ^ (0+5); }
    if (q > 5) { p += (k*1 + 7) ^ (1+5); }
    if (q > 5) { p += (k*2 + 7) ^ (2+5); }
    q = cq_theta(q, 0.9);
    return cq_measure(p) + cq_measure(q);
}
int main(void) { (void)slice(); return 0; }
