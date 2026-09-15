/* o04 — per-cell theta bank PLUS an unrelated register rotated non-diagonally
   between the write loop and the measure loop.  The fence must NOT fire: the
   rotated wire is not any cell's parked rail.  A fence that declines this has
   been seeded with the wrong thing. */
#include "CQ.h"
int main(void) {
    int b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    int q = cq_theta(0, 0.3);
    q = cq_theta(q, 0.7);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s + cq_measure(q);
}
