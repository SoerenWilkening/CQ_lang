/* R2-K — THE ROOT, with NO tainted control flow anywhere: a bounded loop whose
   body mints a per-trip template chain AND reads a loop-invariant tainted
   register.  If this leaks, the class conjunct 2 catches is region-independent
   and the R7 record covers only the R7 slice of it. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
