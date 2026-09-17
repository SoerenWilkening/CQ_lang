// D4 — ISOLATING CONTROL: zujr's carried handle, NO hoisted rail.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
