/* p16.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   (no row recorded)
   ⚠ RETIREMENT TRIGGER (L8): (none) */
/* p16 — the FLAT hand-unrolled twin of p1 (K=3). The byte-identity witness. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    if (b) cq_phi(0.7); b = cq_theta(b, 0.2);
    if (b) cq_phi(0.7); b = cq_theta(b, 0.2);
    if (b) cq_phi(0.7); b = cq_theta(b, 0.2);
    return cq_measure(b);
}
