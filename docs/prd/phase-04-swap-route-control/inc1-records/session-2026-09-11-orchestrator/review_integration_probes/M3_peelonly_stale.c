/* peeled selects ONLY, rail condition, a SIBLING theta on the rail after the def */
#include "CQ.h"
int main(void) {
    int a = 5; int z = 1;
    bool t  = cq_theta((bool)0, 0.1);
    bool b0 = cq_theta(t, 0.5);
    bool c  = cq_theta(t, 0.9);
    if (b0 == 1) { a -= 3; z = 4; }
    return cq_measure(c) + cq_measure(a) + cq_measure(z);
}
