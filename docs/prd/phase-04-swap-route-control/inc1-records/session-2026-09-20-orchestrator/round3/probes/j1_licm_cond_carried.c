// J1 — bd drbq.12 (`crossBlockCompareMintable`, 87 D→A, LANDED on main) composed
// with zujr's carried handle: a LICM-HOISTED loop-invariant compare `q >= 3` as
// the region condition. CLAUDE.md §2 P4: "an unbounded cross-block gap — this is
// why an LICM-hoisted loop-invariant compare declines, so Grover's condition
// register must be loop-variant". drbq.12 relaxes exactly that.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if (q >= 3) b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return slice(4); }
