/* w5_invariant_bool_value.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   The value arm as a SELECT with an invariant bool. Same X1 loop-layer decline. The §4 answer in one line: the loop layer, not 3qlq.6.
   ⚠ RETIREMENT TRIGGER (L8): as t_loop_uncond_value. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; ++i) {
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
