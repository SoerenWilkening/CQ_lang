/* p6.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   boi6 p6, RE-MEASURED: the 4.4 DATA select on a carried bool in a loop -> `loop-carried tainted value crosses iterations`. Same X1 clause as w3/w5.
   ⚠ RETIREMENT TRIGGER (L8): as t_loop_uncond_value. */
/* p6 — the 4.4 DATA select on a CARRIED bool inside a loop. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; i++) {
        int a = b ? 2 : 5;
        acc += a;
        b = cq_theta(b, 0.2);
    }
    return acc + cq_measure(b);
}
