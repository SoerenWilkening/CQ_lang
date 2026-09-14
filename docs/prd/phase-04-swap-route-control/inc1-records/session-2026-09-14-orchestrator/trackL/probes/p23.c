/* p23.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   boi6 p23, RE-MEASURED: the loop-INVARIANT bool (the shipped 1b accept), 6 trace lines. The control for every carried-rail claim here.
   ⚠ RETIREMENT TRIGGER (L8): none. */
/* p23 — the SHIPPED 1b accept: an INVARIANT bool in a classically-bounded loop. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) if (b) cq_phi(0.7);
    return cq_measure(b);
}
