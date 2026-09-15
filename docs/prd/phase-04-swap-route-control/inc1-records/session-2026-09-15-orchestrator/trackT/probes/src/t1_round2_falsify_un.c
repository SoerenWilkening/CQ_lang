/* hand-unrolled twin (K=2) of t1 */
#include "CQ.h"
int slice(void) {
    int q = cq_theta(5, 0.5);
    int y = cq_theta(7, 0.3);
    int a;
    if (q & 1) a = 2; else a = 5;
    int s = 0;
    s += cq_measure((y >> 1) & a);
    s += cq_measure((y >> 2) & a);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(q);
}
int main(void) { return slice(); }
