/* hand-unrolled twin (K=2) of R2-H3 */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int u = cq_theta(6, 0.4); bool b = cq_theta((bool)0, 0.5); int a = b ? 2 : 5;
      s += cq_measure(a) + cq_measure((u >> 1) & 1) + cq_measure(y & 1); }
    { int u = cq_theta(6, 0.4); bool b = cq_theta((bool)0, 0.5); int a = b ? 2 : 5;
      s += cq_measure(a) + cq_measure((u >> 1) & 1) + cq_measure(y & 1); }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
