/* p1.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   boi6 p1, RE-MEASURED on this ORACLE: the carried-bool HEADER PHI as the phase condition -> `branch phase on a bare i1 condition`. bd boi6.a.
   ⚠ RETIREMENT TRIGGER (L8): when boi6.a lands this accepts and prints p16.trace (9 lines). */
/* p1 — the bd's own shape: loop-CARRIED bool as the phase condition. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) {
        if (b) cq_phi(0.7);
        b = cq_theta(b, 0.2);
    }
    return cq_measure(b);
}
