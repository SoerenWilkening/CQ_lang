/* ADV-5 — an IN-PLACE dtzb mutation of the invariant register inside the body.
   `invariantRegisterRootsImpl` clause (iii) refuses a `cq_theta` in-place gate;
   an `add` self-update makes the register loop-CARRIED, so clause (i)'s tainted
   header phi must refuse it. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) {
        s += cq_measure((y >> k) & 1);
        y = y + 3;
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
