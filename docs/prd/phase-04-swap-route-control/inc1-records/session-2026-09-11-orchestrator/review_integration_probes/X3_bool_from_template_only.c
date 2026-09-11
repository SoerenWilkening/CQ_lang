/* a bare i1 that is a TEMPLATE rail, not a cq_theta_i1 result */
#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.3);
    bool b0 = (bool)(q & 1);
    int a = 5; bool b1 = 0;
    if (b0) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
