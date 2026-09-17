// F2 — MULTI-EXIT (a break) with a hoisted rail and a carried handle, no rail
// bank (scalar bool, so `RailBankPromote`'s injectivity fence is not the first
// wall). `loopExitDischargePoint` returns nullptr for a multi-exit loop, so a
// (ii-d) grant here MUST be caught by the postcondition or the rail leaks with
// the dephasing fence already silenced by the marking.
#include "CQ.h"
int slice(int u, int lim) {
    int q = cq_theta(u, 0.5);
    int p = q * 3;
    int a = 5;
    bool b;
    for (int i = 0; i < 3; i++) {
        if (i >= lim) break;
        if ((p >> i) & 1) cq_phi(0.2);
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    q = cq_theta(q, 0.9);
    return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc + 1); }
