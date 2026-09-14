/* Track beta P9 — conjunct (2)'s DOMINANCE gap, isolated.  Same program as
   `s1_live_shift` (which the SUBJECT declines) except the trip count is
   `n & 3`, so `-O1` keeps the zero-trip guard and `L->getHeader()` no longer
   dominates the post-loop rotation's block. */
#include "CQ.h"
int slice(int n) {
    int y = cq_theta(5, 0.5);
    int m = n & 3;
    int s = 0;
    for (int k = 1; k <= m; ++k)
        s += cq_measure((y >> k) & 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
