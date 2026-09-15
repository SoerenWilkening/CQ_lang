/* ADV-1 — a body rail that carries an Ry (`preservesBasisUnderRecord` false), so
   the spine may refuse to discharge it even in a MARKED body.  The register is
   re-rotated after the loop, so a residual leak would be a DIVERGENCE the s82e
   fence can no longer see (conjunct (1) skips a marked body). */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k) {
        int t = (y >> k) & 1;
        t = cq_theta(t, 0.2);
        s += cq_measure(t);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
