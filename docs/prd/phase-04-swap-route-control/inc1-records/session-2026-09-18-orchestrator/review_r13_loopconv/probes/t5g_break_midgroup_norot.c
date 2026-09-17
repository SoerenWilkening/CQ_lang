/* SUBJECT (C) — t5e WITHOUT the post-loop rotation.  The rail is minted BEFORE
   the classical early exit and read AFTER it, so the mint's block and the read's
   block are separated by the break edge: the shape that should defeat
   `Uncomputation`'s post-dominance clause. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k) & 1;
        if (k >= lim) break;
        s += cq_measure(d);
    }
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
