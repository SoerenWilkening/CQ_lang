// C2u — the HAND-UNROLLED twin of c2_carried_plus_hoisted.c.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u, 0.3);
    int p = q * 3;
    int a = 5;
    if ((p >> 0) & 1) a -= 3;
    r = cq_theta(r, 0.1);
    if ((p >> 1) & 1) a -= 3;
    r = cq_theta(r, 0.1);
    if ((p >> 2) & 1) a -= 3;
    r = cq_theta(r, 0.1);
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(void) { return slice(4); }
