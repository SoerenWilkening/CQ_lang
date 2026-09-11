/* M2: M1 with an INT condition (compare) -- the i1 seed under an i32 cond. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.5);
    bool b1 = 0;
    if (q > 5) b1 = cq_theta(b1, 0.5);
    return cq_measure(q) + cq_measure(b1);
}
