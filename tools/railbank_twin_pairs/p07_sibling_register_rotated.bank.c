/* per-cell theta bank PLUS an unrelated register rotated non-diagonally between
   the two loops.  A fence seeded with the WRONG thing declines this; the
   correct seed is the cell's own parked rail, which no gate touches. */
#include "CQ.h"
int slice(void) {
    int b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
    int q = 0; cq_theta(&q, 0.3);
    cq_theta(&q, 0.7);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s + cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
