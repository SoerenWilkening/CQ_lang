// N2 — TWO FUNCTIONS, because bd `1yeu` records that every corpus and gate in
// the tree is effectively ONE FUNCTION PER MODULE, so a cross-function defect is
// invisible to all of them -- and BOTH postconditions here
// (`declineUndischargedExitObligations`, `declineUndischargedMarkedBodyRails`)
// are MODULE-scoped ledgers that CLEAR themselves.  A module with two quantum
// functions, each carrying its own obligation, is the shape where "cleared at
// both ends" could read an emptied ledger.
#include "CQ.h"
__attribute__((noinline)) int fa(int u) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 1) cq_phi(0.2);
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
__attribute__((noinline)) int fb(int u) {
    int q = cq_theta(u, 0.3);
    int p = q * 5;
    int a = 7;
    bool b1[3];
    for (int i = 0; i < 3; i++) {
        if ((p >> i) & 2) cq_phi(0.4);
        b1[i] = cq_theta(b1[i], 0.6);
        if (b1[i]) a -= 2;
    }
    q = cq_theta(q, 0.8);
    return cq_measure(q) + cq_measure(a);
}
int main(void) { return fa(4) + fb(6); }
