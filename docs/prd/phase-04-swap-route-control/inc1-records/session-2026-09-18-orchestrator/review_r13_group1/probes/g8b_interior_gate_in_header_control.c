/* SECOND ISOLATING CONTROL for g8: the interior-rail GATE (`d + 7`) is HOISTED
   into the header block; only its READ (`e & 2`) stays in the arm.  §4's
   DT.dominates(G, At) then holds for the `add`, and the 6n1s relaxation admits
   the arm read.  If this DISCHARGES on the subject and LEAKS on the oracle, the
   discriminant for g8 is exactly "an INTERIOR-rail GATE inside the arm" — a §4
   refusal that `markedBodyRailsHaveInBodyDischargePoint` does not model. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        int e = d + 7;
        s += cq_measure(d & 1);
        if (k < lim) s += cq_measure(e & 2);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
