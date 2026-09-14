/* R2-H3 — an ITERATION-LOCAL in-loop 4.4 DATA SELECT (again not an R7 grant, so
   no record) in a body whose marking is refused by a loop-invariant tainted
   read. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 0; k < 2; ++k) {
        int  u = cq_theta(6, 0.4);
        bool b = cq_theta((bool)0, 0.5);
        int  a = b ? 2 : 5;
        s += cq_measure(a) + cq_measure((u >> 1) & 1) + cq_measure(y & 1);
    }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
