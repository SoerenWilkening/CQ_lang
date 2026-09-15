/* ADV-X2 — the same hazard with a GENUINE out-of-place rail beside the in-place
   one, so if the body were marked the pairing would have something real to
   discharge and the question "did it also try to discharge the in-place relabel?"
   is answerable from the trace rather than from the absence of one. */
#include "CQ.h"
int slice(void) {
    volatile int v = 3;
    int y = cq_theta(5, 0.5);
    int z = cq_theta(7, 0.3);
    int s = 0;
    for (int k = 1; k <= 2; ++k) {
        z ^= v;
        s += cq_measure((y >> k) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(z);
}
int main(void) { return slice(); }
