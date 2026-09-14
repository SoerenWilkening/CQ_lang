/* hand-unrolled twin of w2b_sameloop_mixed_derived (K=2) */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    { if (b) r = cq_theta(r, 0.3);
      int u = cq_theta(5, 0.5); int w = cq_theta(3, 0.15);
      if ((u >> 1) & 1) w = cq_theta(w, 0.2);
      s += cq_measure(r) + cq_measure(w) + cq_measure(u); }
    { if (b) r = cq_theta(r, 0.3);
      int u = cq_theta(5, 0.5); int w = cq_theta(3, 0.15);
      if ((u >> 1) & 1) w = cq_theta(w, 0.2);
      s += cq_measure(r) + cq_measure(w) + cq_measure(u); }
    return s;
}
int main(void) { return slice(); }
