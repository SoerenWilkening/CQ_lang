/* p9.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   boi6 p9, RE-MEASURED: ACCEPT, the NEGATED arm, `cqrt_rz_i1(h0, -θ)`, no cqrt_x. H-10 PIN #2.
   ⚠ RETIREMENT TRIGGER (L8): none. */
/* p9 — NEGATED in-body rail leaf (the theta BEFORE the region): the p2 accept, negated. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) { b = cq_theta(b, 0.2); if (!b) cq_phi(0.7); }
    return cq_measure(b);
}
