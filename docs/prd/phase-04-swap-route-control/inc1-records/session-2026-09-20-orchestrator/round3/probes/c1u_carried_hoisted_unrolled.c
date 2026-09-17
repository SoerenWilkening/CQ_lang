// C1u — the HAND-UNROLLED twin of c1_carried_hoisted.c. Same source, no loop.
#include "CQ.h"
int main(void) {
    int q = cq_theta(5, 0.5);
    int y = q & 1;
    int a = 5;
    bool b0[3];
    if (a >= 3) b0[0] = cq_theta(b0[0], 0.5);
    if (b0[0]) a -= y;
    if (a >= 3) b0[1] = cq_theta(b0[1], 0.5);
    if (b0[1]) a -= y;
    if (a >= 3) b0[2] = cq_theta(b0[2], 0.5);
    if (b0[2]) a -= y;
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
