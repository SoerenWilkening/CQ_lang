/* M3: int seed under int cond -- the drbq Inc-4 shipped accept class (control). */
#include "CQ.h"
int main(void) {
    int q = cq_theta(0, 0.5);
    int r = 7;
    if (q > 5) r = cq_theta(7, 0.5);
    return cq_measure(q) + cq_measure(r);
}
