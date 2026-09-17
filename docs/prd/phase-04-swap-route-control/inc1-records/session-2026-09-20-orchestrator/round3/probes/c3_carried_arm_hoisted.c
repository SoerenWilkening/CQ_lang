// C3 — THE COMPOSITION, built to dodge the 2c condition-wire fence that refused
// C1/C2: the loop CONDITION is a `b0[i]` rail (independent of `q`), so the
// trailing `cq_theta(q,0.9)` is not on the condition's wire.
//   * `p = q & 1`  — the LICM-HOISTED loop-invariant out-of-place TEMPLATE RAIL
//                    (bd `tu9q` clause (ii-d)'s subject; a which-path copy of q).
//   * `a`          — the bd `zujr` LOOP-CARRIED HANDLE VARIABLE, re-minted per trip.
//   * `cq_theta(q,0.9)` after the loop — the Rule-8 interference test on q.
#include "CQ.h"
int slice(int u) {
    int q = cq_theta(u, 0.5);
    int p = q & 1;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= p;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a) + cq_measure(b0[0]);
}
int main(void) { return slice(4); }
