/* w3_value_diamond.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Wall-peel: the value arm as a two-op DIAMOND (not folded to a select), no prep region. DECLINE `loop-carried tainted value crosses iterations` — the LOOP LAYER, before detection. So 3qlq.6's in-loop value-arm decline is UNREACHABLE for this customer; the X1 clause owns it.
   ⚠ RETIREMENT TRIGGER (L8): as t_loop_uncond_value. */
#include "CQ.h"
int main(void) {
    int a = 5; int z = 0;
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        if (b) { a -= 3; z += 4; }
    }
    return cq_measure(a) + z + cq_measure(b);
}
