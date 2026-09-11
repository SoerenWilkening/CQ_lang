/* peeled selects ONLY (no prep), rail condition, b0 MEASURED before */
#include "CQ.h"
int main(void) {
    int a = 5; int z = 1;
    bool b0 = cq_theta((bool)0, 0.5);
    int m = cq_measure(b0);
    if (b0 == 1) { a -= 3; z = 4; }
    return m + cq_measure(a) + cq_measure(z);
}
