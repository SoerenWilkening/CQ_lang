/* ATTACK B6 — b3 (c2 one loop deeper) PLUS the post-loop non-diagonal gate on
   `y`, so the nested divergence b3 exposed stands at a real interference. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i)
        for (int k = 0; k < 2; ++k) {
            int u = cq_theta(6, 0.4);
            s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
            u = cq_theta(u, 0.9);
            s += cq_measure(u);
        }
    y = cq_theta(y, 0.7);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
