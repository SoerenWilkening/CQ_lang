/* ONE-TOKEN ISOLATING CONTROL for g8: the arm's `(d + 7) & 2` becomes `d + 7`,
   so the arm's template rail is MEASURE-OWNED instead of INTERIOR.  If this
   DISCHARGES while g8 leaks, the discriminant is "the arm mints an INTERIOR
   rail", and §4's unrelaxed DT.dominates(G, At) is the refusal — a mechanism
   `markedBodyRailsHaveInBodyDischargePoint` does not model. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim) { int e = d + 7; s += cq_measure(e); }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
