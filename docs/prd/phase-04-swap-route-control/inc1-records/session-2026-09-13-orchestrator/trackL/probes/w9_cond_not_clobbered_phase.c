/* w9_cond_not_clobbered_phase.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   w8 with a phase arm. Same 2c wall, same anchor.
   ⚠ RETIREMENT TRIGGER (L8): as w1. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(9, 0.2);
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        if (q >= 3) b = cq_theta(b, 0.5);
        if (b) cq_phi(0.3);
    }
    return cq_measure(b) + cq_measure(q);
}
