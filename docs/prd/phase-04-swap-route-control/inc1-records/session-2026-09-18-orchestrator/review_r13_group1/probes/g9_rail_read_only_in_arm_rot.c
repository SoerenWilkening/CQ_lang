/* PART A — the interior rail's ONLY use is inside the classical arm.  The
   discharge point (pdom of the anchors) is then INSIDE the arm, while the MINT
   is in the header and runs on both paths.  §4's PDT.dominates(At->BB, G->BB)
   must refuse; a one-armed reversal would leave the other path's rail dirty. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        if (k < lim) s += cq_measure(d & 2);
        s += k;
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
