/* PART A — an IN-PLACE (M-C) loop-carried rail mutated every trip, in a
   TWO-BLOCK marked body.  The in-place gate relabels the rail; the interior
   rail `d` straddles the split. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int acc = cq_theta(0, 0.25);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        acc ^= d;
        s += cq_measure(d & 1);
        if (k < lim) s += cq_measure(d & 2);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(acc) + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
