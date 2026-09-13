/* a_flat_n3.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) HAND-UNROLLED, N=3. Scalarised likewise; declines `state prep seed is proven equal to the condition register` — the same F2/prep wall ../probes/vd.c takes.
   ⚠ RETIREMENT TRIGGER (L8): as a_flat_n2 (Track M/R). */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[3] = {0};
    if (a >= 3) b[0] = cq_theta(b[0], 0.5);
    if (b[0]) a -= 3;
    if (a >= 3) b[1] = cq_theta(b[1], 0.5);
    if (b[1]) a -= 3;
    if (a >= 3) b[2] = cq_theta(b[2], 0.5);
    if (b[2]) a -= 3;
    return cq_measure(a) + cq_measure(b[0]) + cq_measure(b[1]) + cq_measure(b[2]);
}
