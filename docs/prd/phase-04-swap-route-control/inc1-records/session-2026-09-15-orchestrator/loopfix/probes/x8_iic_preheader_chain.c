/* R13-r2 X8 — (ii-c) admits the hoisted `and`, but its OWN preheader ancestor
   (`y >> 3`) is an ordinary INTERIOR template rail with a real free point.
   The multiplicity argument T states covers V and not V's chain. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int u = cq_theta(6, 0.4);
        s += cq_measure((u >> 1) & 1) + cq_measure((y >> 3) & 1);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
