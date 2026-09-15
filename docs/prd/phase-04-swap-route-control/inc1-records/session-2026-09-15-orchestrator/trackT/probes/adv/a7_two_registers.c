/* ADV-7 — TWO loop-invariant root-mint registers read in the body, both
   re-rotated after the loop.  Exercises a multi-root `Roots` set. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int z = cq_theta(6, 0.4);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(((y >> k) & 1) + ((z >> k) & 1));
    y = cq_theta(y, 0.9);
    z = cq_theta(z, 0.7);
    return s + cq_measure(y) + cq_measure(z);
}
int main(void) { return slice(); }
