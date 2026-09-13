/* t_loop_uncond_value_inv.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   The same with a loop-INVARIANT bool and no prep. Same X1 decline — so the value arm's wall is independent of the condition's loop disposition.
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
