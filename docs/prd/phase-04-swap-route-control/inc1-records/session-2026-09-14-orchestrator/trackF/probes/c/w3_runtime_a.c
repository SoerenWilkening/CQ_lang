/* C3 (corrected) — the cascade with a RUNTIME `a`, so the F2 pin is RANGE-derived
   and not IPSCCP-constant-derived, while region 1 stays QUANTUM-conditioned (in
   w2.c the first guard folds to `icmp sgt %argc, -2`, a CLASSICAL branch, which
   is a different shape and a different, pre-existing wall). */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int a = argc + 4;
    bool b0 = 0; bool b1 = 0; bool b2 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    if (a >= 3) { b2 = cq_theta(b2, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2) + cq_measure(a);
}
