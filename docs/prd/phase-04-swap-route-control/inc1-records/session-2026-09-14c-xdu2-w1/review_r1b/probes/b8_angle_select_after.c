/* Track beta P8 — the same question for the FOLDED ANGLE SELECT (Ry stem,
   constant arms), which `AngleSelectEmit` lowers by DIFFERENCE. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int b = cq_theta(0, 0.3);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) & 1);
    y = cq_theta(y, b ? 0.9 : 0.2);
    return s + cq_measure(y) + cq_measure(b);
}
int main(void) { return slice(); }
