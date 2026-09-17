/* PART A — the rail is MINTED inside one arm of an in-body classical `if` and
   read after the join.  §4's unrelaxed DT.dominates(G, At) must refuse the
   component (the mint runs on one path; a join discharge would adjoint a gate
   that never fired).  A `_unc` at the join would be a WRONG UNITARY. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = 0;
        if (k < lim) d = (y >> k);
        s += cq_measure(d & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
