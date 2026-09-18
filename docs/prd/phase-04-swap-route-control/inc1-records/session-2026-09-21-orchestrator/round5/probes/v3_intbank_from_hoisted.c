// V3 — an INTEGER bank whose cells are written from the hoisted rail.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int c[3];
    for (int i = 0; i < 3; i++) {
        c[i] = p + i;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(c[0]);
}
int main(void) { return slice(4); }
