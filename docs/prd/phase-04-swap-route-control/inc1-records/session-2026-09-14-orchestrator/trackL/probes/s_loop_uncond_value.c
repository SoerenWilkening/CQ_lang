/* s_loop_uncond_value.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Same with a VALUE arm. Same classical-mux decline.
   ⚠ RETIREMENT TRIGGER (L8): as s_loop_phase, then the loop layer (L-4). */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = 0;
    for (int i = 0; i < 3; ++i) {
        b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
