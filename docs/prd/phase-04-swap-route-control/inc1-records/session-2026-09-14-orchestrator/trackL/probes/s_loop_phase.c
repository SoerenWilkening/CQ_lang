/* s_loop_phase.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(ii) with a PHASE arm, owner seed `bool b = 0`. `a` is never written so -O1 const-folds `a>=3` away: the shape reduces to p2's, but the header phi's external incoming is the CLASSICAL `false`, so the rail has no root mint and the collapse refuses it -> `tainted value muxed by a classical-condition phi` (TaintPropagation.cpp:958).
   ⚠ RETIREMENT TRIGGER (L8): when the classical-seed rail root (L-3) is materialised in the preheader as cqrt_alloc_i1(0) this becomes p2's accept exactly. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = 0;
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) cq_phi(0.3);
    }
    return cq_measure(a) + cq_measure(b);
}
