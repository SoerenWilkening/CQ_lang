/* p2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   boi6 p2, RE-MEASURED: ACCEPT rolled, 9 trace lines, 50 lowered IR lines (no -g). H-10 PIN #1 — see ../ready/.
   ⚠ RETIREMENT TRIGGER (L8): none; it must stay byte-identical forever. */
/* p2 — the theta BEFORE the region in the body. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) {
        b = cq_theta(b, 0.2);
        if (b) cq_phi(0.7);
    }
    return cq_measure(b);
}
