/* a_loop_n8.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) ARRAY spelling, N=8. Same decline — the wall is N-INDEPENDENT.
   ⚠ RETIREMENT TRIGGER (L8): same as a_loop_n2; the N-independence is the point (no small-N carve exists). */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[8] = {0};
    for (int i = 0; i < 8; ++i) {
        if (a >= 3) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) a -= 3;
    }
    int s = cq_measure(a);
    for (int i = 0; i < 8; ++i) s += cq_measure(b[i]);
    return s;
}
