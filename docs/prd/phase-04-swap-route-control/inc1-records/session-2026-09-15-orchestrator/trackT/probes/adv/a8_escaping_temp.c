/* ADV-8 — a body temp whose value ESCAPES the loop (read after it).  The
   marking's escape clause must refuse; if it granted, the spine would discharge
   in-body a rail still live at the exit. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int t = 0;
    for (int k = 1; k <= 2; ++k)
        t = (y >> k) & 1;
    y = cq_theta(y, 0.9);
    return cq_measure(t) + cq_measure(y);
}
int main(void) { return slice(); }
