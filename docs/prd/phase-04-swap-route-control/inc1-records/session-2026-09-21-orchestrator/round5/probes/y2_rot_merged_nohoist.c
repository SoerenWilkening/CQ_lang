// Y2 — Y1 WITHOUT the hoisted rail `p`, i.e. bd zujr's shipped carried-handle
// cascade alone plus the trailing rotation on `a`.  The CONTROL that says whether
// Y1's verdict is the composition's doing or pre-existing on MAIN.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    a = cq_theta(a, 0.7);
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
