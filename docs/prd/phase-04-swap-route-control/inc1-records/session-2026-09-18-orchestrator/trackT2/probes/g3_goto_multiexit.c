/* FENCE-CUSTOMER CANDIDATE 3 for bd `test_C_libtooling-6n1s`: two DISTINCT
   exiting blocks that reconverge only AFTER the loop, with the rail used in
   both, so `dagInsertPoint`'s post-dominator escapes `L`. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int k = 1;
    for (; k <= 4; ++k) {
        int d = (y >> k);
        if (k >= lim) { s += cq_measure(d & 1); goto out; }
        s += cq_measure(d & 2);
        if (s > 7) { s += cq_measure(d & 4); goto out; }
    }
out:
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
