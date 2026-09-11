/* p34 — the carried bool's region is the ONLY body content (no per-trip theta):
   b is then loop-INVARIANT again; the control for p1. */
#include "CQ.h"
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    for (int i = 0; i < 3; i++) if (b) cq_phi(0.7);
    return cq_measure(b);
}
