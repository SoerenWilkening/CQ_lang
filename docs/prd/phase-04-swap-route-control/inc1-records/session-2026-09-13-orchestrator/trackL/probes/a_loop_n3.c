/* a_loop_n3.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) ARRAY spelling, N=3 — byte-identical source to ../probes/ve.c. Same decline, same site, col 26.
   ⚠ RETIREMENT TRIGGER (L8): same as a_loop_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[3] = {0};
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) a -= 3;
    }
    int s = cq_measure(a);
    for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
    return s;
}
