/* hand-unrolled twin of w2b_sameloop_mixed (K=2) */
#include "CQ.h"
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int  r = cq_theta(7, 0.25);
    int  s = 0;
    { if (b) r = cq_theta(r, 0.3);
      bool t = cq_theta((bool)0, 0.4); int w = cq_theta(3, 0.15);
      if (t) w = cq_theta(w, 0.2);
      s += cq_measure(r) + cq_measure(w) + cq_measure(t); }
    { if (b) r = cq_theta(r, 0.3);
      bool t = cq_theta((bool)0, 0.4); int w = cq_theta(3, 0.15);
      if (t) w = cq_theta(w, 0.2);
      s += cq_measure(r) + cq_measure(w) + cq_measure(t); }
    return s;
}
int main(void) { return slice(); }
