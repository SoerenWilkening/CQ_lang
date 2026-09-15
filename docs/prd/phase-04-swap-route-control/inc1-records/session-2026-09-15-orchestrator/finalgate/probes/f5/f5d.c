/* F-5 probe d: the control for f5a -- the same program with u initialised to 0.
   E2's refinement claim says f5a's TRACE must equal this one's. */
#include "CQ.h"
int slice(void) {
    bool b0[3];
    int u = 0;
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    s += cq_measure(u);
    return s;
}
int main(void) { (void) slice(); return 0; }
