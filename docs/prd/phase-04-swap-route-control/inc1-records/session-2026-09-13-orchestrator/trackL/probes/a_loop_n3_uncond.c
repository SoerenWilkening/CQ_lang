/* a_loop_n3_uncond.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) with the prep UNCONDITIONAL (no region at all). STILL the escape decline at col 14 — proof the array wall is upstream of all control work.
   ⚠ RETIREMENT TRIGGER (L8): same as a_loop_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[3] = {0};
    for (int i = 0; i < 3; ++i) {
        b[i] = cq_theta(b[i], 0.5);
        if (b[i]) a -= 3;
    }
    return cq_measure(a) + cq_measure(b[0]) + cq_measure(b[1]) + cq_measure(b[2]);
}
