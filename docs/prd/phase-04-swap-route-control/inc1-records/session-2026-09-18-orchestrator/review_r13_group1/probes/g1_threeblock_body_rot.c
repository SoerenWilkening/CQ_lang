/* PART A — a THREE-block marked body.  The rail `d` is read in the header block,
   in arm A and in arm B; the discharge must be at the join and must run once per
   trip against a once-per-trip mint.  Post-loop non-diagonal gate + measure on
   the register the rail copies => Rule 8 if it leaks. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim)        s += cq_measure(d & 2);
        else if (k > lim+1) s += cq_measure(d & 4);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
