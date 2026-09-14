/* w8_cond_not_clobbered.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Wall-peel: the prep condition reads a DIFFERENT quantum register `q`, so nothing clobbers it. Next wall = `condition predates a non-diagonal gate` on the LICM-hoisted `icmp sgt i32 %1, 2`. Proves the clobber fence is not the only prep-region wall.
   ⚠ RETIREMENT TRIGGER (L8): as w1. */
#include "CQ.h"
int main(void) {
    int a = 5;
    int q = cq_theta(9, 0.2);
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        if (q >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b) + cq_measure(q);
}
