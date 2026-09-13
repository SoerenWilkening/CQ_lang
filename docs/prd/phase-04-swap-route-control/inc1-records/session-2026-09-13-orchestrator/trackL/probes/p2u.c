/* p2u.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   p2 hand-unrolled K=3. ACCEPT; trace byte-identical to p2 (9 = 9). The twin oracle for pin #1.
   ⚠ RETIREMENT TRIGGER (L8): none. */
/* p2u — hand-unrolled twin of p2 (K=3). */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    b = cq_theta(b, 0.2); if (b) cq_phi(0.7);
    b = cq_theta(b, 0.2); if (b) cq_phi(0.7);
    b = cq_theta(b, 0.2); if (b) cq_phi(0.7);
    return cq_measure(b);
}
