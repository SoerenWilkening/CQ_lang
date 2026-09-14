/* R2-E1 — newly admitted rail region + TWO independent per-trip derived chains. */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5);
        int v = cq_theta(6, 0.4);
        if (b) r = cq_theta(r, 0.3);
        s += cq_measure((u >> 1) & 1) + cq_measure((v >> 2) & 3);
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
