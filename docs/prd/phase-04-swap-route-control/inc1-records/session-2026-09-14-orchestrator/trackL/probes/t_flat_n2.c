/* t_flat_n2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   The theta-seeded flat twin. `condition predates a non-diagonal gate` at the prep compare.
   ⚠ RETIREMENT TRIGGER (L8): as s_flat_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.0);
    if (a >= 3) b = cq_theta(b, 0.5);
    if (b) a -= 3;
    if (a >= 3) b = cq_theta(b, 0.5);
    if (b) a -= 3;
    return cq_measure(a) + cq_measure(b);
}
