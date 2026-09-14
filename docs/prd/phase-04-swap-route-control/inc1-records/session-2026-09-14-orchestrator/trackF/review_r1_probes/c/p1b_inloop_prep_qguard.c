#include "CQ.h"
/* p1b — in-loop state prep under a QUANTUM guard (F2 only runs for a tainted
   condition), with the prepped bool CARRIED across the back edge so the loop
   header phi is a user of the region's merge phi. */
int main(void) {
    bool q = cq_theta(0, 0.3);
    bool v = 0;
    int s = 0;
    for (int i = 0; i < 3; i++) {
        bool b = 0;
        if (q) { b = cq_theta(b, 0.5); }
        s += cq_measure(v);
        v = b;                       /* v's header phi takes M on the back edge */
    }
    return s + cq_measure(q);
}
