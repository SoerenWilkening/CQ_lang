/* hand-unrolled twin (K=2) of R2-I2 */
#include "CQ.h"
int ext_f(int a);
int slice(void) {
    int q = cq_theta(3, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int s = 0;
    { int r = cq_theta(7, 0.25); bool t = cq_theta((bool)0, 0.4);
      if (t) r = cq_theta(r, 0.2);
      if (y > 50) cq_phi(0.3);
      s += cq_measure(r) + cq_measure(t); }
    { int r = cq_theta(7, 0.25); bool t = cq_theta((bool)0, 0.4);
      if (t) r = cq_theta(r, 0.2);
      if (y > 50) cq_phi(0.3);
      s += cq_measure(r) + cq_measure(t); }
    return s + cq_measure(y);
}
int main(void) { return slice(); }
