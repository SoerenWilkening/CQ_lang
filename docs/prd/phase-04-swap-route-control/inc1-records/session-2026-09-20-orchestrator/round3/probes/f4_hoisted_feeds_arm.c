// F4 — the HOISTED rail feeds the VALUE ARM of the carried handle (not the
// phase arm's condition). The arm chain `a - p` is hoisted into the pred by
// `emitValueRegion`, so the merge source is a Q+Q op over a preheader rail and
// a per-trip register — the two multiplicities meeting in one chain.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a = a - p;
    }
    return cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
