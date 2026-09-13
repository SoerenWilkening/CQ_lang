/* p9u.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   p9 hand-unrolled K=3 (written this session). ACCEPT; trace byte-identical to p9.
   ⚠ RETIREMENT TRIGGER (L8): none. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    b = cq_theta(b, 0.2); if (!b) cq_phi(0.7);
    b = cq_theta(b, 0.2); if (!b) cq_phi(0.7);
    b = cq_theta(b, 0.2); if (!b) cq_phi(0.7);
    return cq_measure(b);
}
