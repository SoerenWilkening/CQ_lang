// D3 — ISOLATING CONTROL: tu9q's phase arm on a hoisted rail, NO carried handle.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
    }
    return cq_measure(q) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
