/* Track beta P7c — bd `s82e` exhibit `w2h` (PHASE region) + ONE line of
   interference on the per-trip register. */
#include "CQ.h"
int slice(void) {
    int  y = cq_theta(5, 0.5);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        if ((u >> 1) & 1) cq_phi(0.3);
        s += cq_measure((u >> 2) & 1) + cq_measure(y & 1);
        u = cq_theta(u, 0.9);
        s += cq_measure(u);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
