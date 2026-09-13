/* s_loop_n2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(ii) SCALAR spelling with the OWNER'S SEED `bool b = 0`, N=2, ROLLED. DECLINE `arm rewrites a condition operand` (ArmClassify.cpp:4593, diagonalAliasHit + StraightThrough; anchor = the prep arm's `zext i1 -> i8`). The clobber is ONLY around the BACK EDGE.
   ⚠ RETIREMENT TRIGGER (L8): when the §3c clobber fence becomes per-activation (L-2) this declines one wall later — the classical-seed rail-root wall (L-3) — not an accept. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = 0;
    for (int i = 0; i < 2; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
