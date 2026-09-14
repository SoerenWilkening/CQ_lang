/* hand-unrolled twin (K=2) of R2-H2 */
#include "CQ.h"
int slice(void) {
    int  y = cq_theta(5, 0.5);
    int  s = 0;
    { int u = cq_theta(6, 0.4); if ((u >> 1) & 1) cq_phi(0.3);
      s += cq_measure((u >> 2) & 1) + cq_measure(y & 1); }
    { int u = cq_theta(6, 0.4); if ((u >> 1) & 1) cq_phi(0.3);
      s += cq_measure((u >> 2) & 1) + cq_measure(y & 1); }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
