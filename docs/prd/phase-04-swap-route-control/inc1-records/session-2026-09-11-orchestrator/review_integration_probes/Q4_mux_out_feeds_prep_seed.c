/* the peeled mux's %out feeds the PREP's seed via a cast (round-2 taint into l4x4) */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    bool s = (bool)(a & 1);
    bool b1 = 0;
    if (b0 == 1) b1 = cq_theta(s, 0.5);
    return cq_measure(b0)+cq_measure(b1)+cq_measure(a);
}
