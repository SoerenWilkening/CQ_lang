// O1 — THE OWNER'S OWN ROLLED CASCADE (CLAUDE.md §4e, the bd zujr landing) with
// ONE line added: a LICM-hoisted `p = q*3` rail read by the body. This is the
// composition stated as a change to the program the owner actually runs.
#include "CQ.h"
int main(void) {
    int q = cq_theta(5, 0.5);
    int p = q * 3;
    int a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) {
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a) + cq_measure(q);
}
