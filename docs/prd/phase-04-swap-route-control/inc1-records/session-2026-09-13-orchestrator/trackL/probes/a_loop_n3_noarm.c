/* a_loop_n3_noarm.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) with the VALUE ARM deleted (prep region only). STILL the escape decline: the subject is the STORE, not the arm.
   ⚠ RETIREMENT TRIGGER (L8): same as a_loop_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[3] = {0};
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) b[i] = cq_theta(b[i], 0.5);
    }
    return cq_measure(a) + cq_measure(b[0]) + cq_measure(b[1]) + cq_measure(b[2]);
}
