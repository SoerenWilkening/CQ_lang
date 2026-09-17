// K1 — the CARRIED HANDLE's exit value is itself ROTATED after the loop, while a
// hoisted (ii-d) rail lives in the body. Every per-trip `add` rail is a which-path
// copy of the `a` chain, and now `a` is the register a non-diagonal gate runs on.
// If those rails are left dirty across `cq_theta(a, 0.7)` that IS the Rule-8
// dephasing bd tu9q's own text describes, on zujr's rail rather than on q.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    a = cq_theta(a, 0.7);
    return cq_measure(a) + cq_measure(q);
}
int main(void) { return slice(4); }
