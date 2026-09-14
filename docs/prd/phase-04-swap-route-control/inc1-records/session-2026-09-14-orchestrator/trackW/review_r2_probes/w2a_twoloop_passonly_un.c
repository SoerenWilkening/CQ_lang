/* hand-unrolled twin of w2a_twoloop_passonly (K=2) */
#include "CQ.h"
int slice(void) {
    int s = 0;
    { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25);
      if (t) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    { bool t = cq_theta((bool)0, 0.5); int r = cq_theta(7, 0.25);
      if (t) r = cq_theta(r, 0.2); s += cq_measure(r) + cq_measure(t); }
    { bool t2 = cq_theta((bool)0, 0.6); int r2 = cq_theta(9, 0.35);
      if (t2) r2 = cq_theta(r2, 0.3); s += cq_measure(r2) + cq_measure(t2); }
    { bool t2 = cq_theta((bool)0, 0.6); int r2 = cq_theta(9, 0.35);
      if (t2) r2 = cq_theta(r2, 0.3); s += cq_measure(r2) + cq_measure(t2); }
    return s;
}
int main(void) { return slice(); }
