/* R2-F — K-INDEPENDENCE of the newly admitted rail-in-loop family: the lowered
   IR must not grow with the trip count (the rolled claim). */
#include "CQ.h"
#ifndef CQ_K
#define CQ_K 3
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int u = cq_theta(5, 0.5);
        if (b) r = cq_theta(r, 0.3);
        s += cq_measure((u >> 1) & 1);
    }
    return s + cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
