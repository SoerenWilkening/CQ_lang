/* Track S — DETERMINING PROBE (B): an in-loop PHASE region whose invariant base
   is DERIVED (`p = y*3`), so `invariantRegisterRoots` clause (ii) refuses it and
   `markIfRailLocal`'s "accumulating loop-invariant tainted input" fires — while
   the underlying register `y` is LIVE after the loop and re-rotated. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int p = y * 3;
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        if ((p >> k) & 1) cq_phi(0.3);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
