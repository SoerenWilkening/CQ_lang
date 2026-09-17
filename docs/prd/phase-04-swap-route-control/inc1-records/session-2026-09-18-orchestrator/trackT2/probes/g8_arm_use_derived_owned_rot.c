/* PART A, F-R1-3 case (a): the rail `d` has a use INSIDE the arm which is itself
   a template producer whose rail is consumed in the arm; `e` is derived from `d`
   and both are interior.  §4's unrelaxed DT.dominates(G, At) must refuse any
   component whose adjointed gate sits in the arm. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim) { int e = d + 7; s += cq_measure(e & 2); }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
