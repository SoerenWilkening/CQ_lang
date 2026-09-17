/* PART A, the §8-item-1 attack: a CONDITIONAL IN-PLACE gate on the OWNED rail.
   `d ^= 3` inside the arm mutates the rail on ONE path only.  If it reaches the
   relaxed leg of useCompleteBeforeDischarge and the component is still planned,
   the adjoint fires on both paths => WRONG UNITARY. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        if (k < lim) d ^= 3;
        s += cq_measure(d & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
