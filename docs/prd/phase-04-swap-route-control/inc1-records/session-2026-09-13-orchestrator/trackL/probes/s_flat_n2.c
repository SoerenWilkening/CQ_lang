/* s_flat_n2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(ii) HAND-UNROLLED N=2: the flat twin of the scalar spelling. DECLINE `condition predates a non-diagonal gate` — so spelling (ii) has NO working flat twin and therefore NO cross-binary oracle stream.
   ⚠ RETIREMENT TRIGGER (L8): when 2c's per-activation reading covers a chained rail (drbq.12 / A.2) this accepts and BECOMES the twin oracle for s_loop_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = 0;
    if (a >= 3) b = cq_theta(b, 0.5);
    if (b) a -= 3;
    if (a >= 3) b = cq_theta(b, 0.5);
    if (b) a -= 3;
    return cq_measure(a) + cq_measure(b);
}
