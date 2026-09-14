/* R2-A' — the same module with the two loops in the opposite order. */
#include "CQ.h"
int slice(void) {
    int s = 0;
    for (int k = 0; k < 2; ++k) {                 /* loop 1 — MUST DECLINE */
        int u = cq_theta(5, 0.5);
        int r = cq_theta(7, 0.25);
        if ((u >> 1) & 1) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(u);
    }
    for (int k = 0; k < 2; ++k) {                 /* loop 2 — PASSES */
        bool t = cq_theta((bool)0, 0.5);
        int r = cq_theta(7, 0.25);
        if (t) r = cq_theta(r, 0.2);
        s += cq_measure(r) + cq_measure(t);
    }
    return s;
}
int main(void) { return slice(); }
