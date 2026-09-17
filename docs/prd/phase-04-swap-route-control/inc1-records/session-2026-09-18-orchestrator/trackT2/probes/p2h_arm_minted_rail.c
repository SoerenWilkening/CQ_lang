/* bd `6n1s`, the REVIEWER'S CLOSING LENS: a rail MINTED IN ONE ARM of an in-body
   classical `if`, inside a MARKED multi-block body.

   THE HAZARD IF THE RELAXATION WERE WRONG: the mint runs on one path and the
   discharge would sit at the join, so the adjoint would fire on a path where the
   forward gate never did — a wrong unitary, not a leak. The relaxation deliberately
   touches only the USE side; §4's `DT.dominates(G, At)` is UNCHANGED and is what
   must refuse this, because an arm block does not dominate the join.

   EXPECTED: the component LEAKS (no `ashr…_unc`, no `cqrt_free` for it). A
   discharge appearing here means the relaxation reached the GATE side. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        if (k < lim) {
            int d = (y >> k);              /* MINTED IN THE ARM */
            s += cq_measure(d & 1);
            s += cq_measure(d & 2);
        }
        s += cq_measure(y & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
