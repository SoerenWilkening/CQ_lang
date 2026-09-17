/* FENCE-CUSTOMER CANDIDATE 1 for bd `test_C_libtooling-6n1s`'s conjunct-(1)
   second half: the rail's second use sits in an EARLY-RETURN block, so the two
   use blocks reconverge only at the function exit and no in-body post-dominator
   exists. */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k >= lim) { s += cq_measure(d & 2); return s; }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
