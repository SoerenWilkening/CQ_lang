/* t_loop_n2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(ii) with a THETA-SEEDED rail (`bool b = cq_theta(0,0.0)`), N=2 — L-3 peeled by hand. DECLINE `arm rewrites a condition operand`, ArmClassify.cpp:4593, anchor `%17 = zext i1 %16 to i8`. PROVES the clobber fence, not the seed, is the first wall once the root mint exists.
   ⚠ RETIREMENT TRIGGER (L8): as s_loop_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 2; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
