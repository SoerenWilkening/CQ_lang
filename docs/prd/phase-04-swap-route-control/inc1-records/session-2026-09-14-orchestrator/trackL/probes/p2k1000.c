/* p2k1000.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   p2 at K=1000. ACCEPT; 2003 trace lines and **50 lowered IR lines — identical to K=3**. The K-independence measurement.
   ⚠ RETIREMENT TRIGGER (L8): none. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 1000; i++) {
        b = cq_theta(b, 0.2);
        if (b) cq_phi(0.7);
    }
    return cq_measure(b);
}
