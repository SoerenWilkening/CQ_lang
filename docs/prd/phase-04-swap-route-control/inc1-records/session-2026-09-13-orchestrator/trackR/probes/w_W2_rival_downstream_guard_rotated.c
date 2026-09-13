/* W2 — vd's collider written as a RIVAL: the arm rotates the DOWNSTREAM
   region's guard flag `c` in place, and `c` is still the guard.  If CQ lowers
   this, vd's collider is a real one and may not be excluded. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0; bool b2 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 1) a -= 3;
    bool c = (a >= 3);
    if (b0) { b1 = cq_theta(c, 0.5); }
    if (c) { b2 = cq_theta(b2, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(b2) + cq_measure(a);
}
