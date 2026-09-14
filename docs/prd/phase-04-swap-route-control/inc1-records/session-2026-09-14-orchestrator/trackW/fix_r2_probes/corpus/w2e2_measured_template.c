/* R2-E2 — newly admitted rail region + a per-trip template rail whose ONLY
   consumer is a measurement (the `od4` shape, now beside a rail region). */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(5, 0.5);
        if (b) r = cq_theta(r, 0.3);
        s += cq_measure(u & 3);
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
