// G5 — (L3) trigger, fifth construction: a bank cell XOR'd with a HOISTED
// loop-invariant template rail, i.e. the (ii-d) subject stored into the bank.
#include "CQ.h"
int slice(int u) {
    int c[3];
    int q = cq_theta(u, 0.5);
    int p = q & 1;
    for (int i = 0; i < 3; i++) {
        c[i] = cq_theta(c[i], 0.5);
        c[i] = c[i] ^ p;
        if (c[i] & 1) cq_phi(0.2);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(c[0]);
}
int main(void) { return slice(4); }
