/* R2-4 — tainted-index MEMORY in the body (L3, the kMsgQramLoop owner's).  The
   marking predicate must refuse before the spine is granted anything. */
#include "CQ.h"
int slice(void) {
    int tbl[8] = {0,1,2,3,4,5,6,7};
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure(tbl[(y >> k) & 7]);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
