/* t_loop_uncond_value.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Theta-seeded, unconditional prep, VALUE arm. DECLINE `cq loop lowering: loop-carried tainted value crosses iterations` (LoopLowering.cpp:2108, the X1 clause: the latch incoming peels to a FRESH value-op rail). The loop layer runs at CQLoweringPass.cpp:373, BEFORE detection at :455.
   ⚠ RETIREMENT TRIGGER (L8): when the in-loop value/select merge lands (L-4 = bd 3qlq.6 + the X1 clause) this accepts with a per-activation controlled-copy merge. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
