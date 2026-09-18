// V2 — the cell is PREPPED by cq_theta (so it is a genuine rail the bank owns) and
// then MUTATED by a template op reading the hoisted rail.  If the mutation lowers
// out of place, the bank cell then names a `cq_template_*` rail.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        b0[i] = cq_theta(b0[i], 0.5);
        b0[i] = b0[i] ^ ((p >> i) & 1);
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
