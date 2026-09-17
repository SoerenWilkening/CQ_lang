// H3 — tu9q's ht_rolled.c skeleton with zujr's CARRIED HANDLE on a bool rail
// condition, single-exit. The composed customer, no break.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u, 0.3);
    int p = q * 3;
    int a = 5;
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        r = cq_theta(r, 0.1);
        if (r >= 0) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(void) { return slice(4); }
