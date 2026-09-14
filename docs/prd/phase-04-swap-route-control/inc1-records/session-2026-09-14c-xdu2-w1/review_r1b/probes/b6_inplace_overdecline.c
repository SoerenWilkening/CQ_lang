/* Track beta P6 — IMPL_S §16.3: a dtzb IN-PLACE rail op passes conjunct (3)
   (it is a BinaryOperator with a stem) yet mints NO rail, so firing on it is an
   OVER-DECLINE.  `y ^= k` is not affine, so `-O1` cannot close-form it away,
   and the `n & 3` bound keeps the trip count classically bounded. */
#include "CQ.h"
int slice(int n) {
    int y = cq_theta(5, 0.5);
    int m = n & 3;
    for (int k = 0; k < m; ++k)
        y ^= k;                    /* in-place: relabels the rail, mints nothing */
    y = cq_theta(y, 0.9);
    return cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
