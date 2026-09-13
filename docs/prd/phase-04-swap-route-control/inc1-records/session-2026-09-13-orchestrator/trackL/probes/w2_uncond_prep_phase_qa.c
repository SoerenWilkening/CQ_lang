/* w2_uncond_prep_phase_qa.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   **ACCEPT, 12 trace lines, 2 rails left allocated.** Unconditional in-body prep + phase arm on the carried bool, with a second quantum register present. The in-loop carried-_Bool phase kickback WORKS today; the cascade's problem is the prep REGION and the value arm, not the loop.
   ⚠ RETIREMENT TRIGGER (L8): none — this is the shipped accept the increments must keep byte-identical. */
#include "CQ.h"
int main(void) {
    int a = cq_theta(5, 0.1);
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 3; ++i) {
        b = cq_theta(b, 0.5);
        if (b) cq_phi(0.3);
    }
    return cq_measure(a) + cq_measure(b);
}
