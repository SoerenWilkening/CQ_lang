/* s_loop_uncond_phase.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   p2's shape with the OWNER'S classical seed instead of a pre-loop theta. DECLINE `muxed by a classical-condition phi`. THE MINIMAL WITNESS that `bool b = 0` alone — no cascade, no value arm — is a wall.
   ⚠ RETIREMENT TRIGGER (L8): as s_loop_phase; this is L-3's red-green program. */
#include "CQ.h"
int main(void) {
    bool b = 0;
    for (int i = 0; i < 3; ++i) {
        b = cq_theta(b, 0.2);
        if (b) cq_phi(0.7);
    }
    return cq_measure(b);
}
