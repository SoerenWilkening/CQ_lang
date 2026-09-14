/* hand-unrolled twin (K=2) of R2-I */
#include "CQ.h"
__attribute__((noinline)) int g(int x) { return x * 3; }
int slice(void) {
    int q = cq_theta(5, 0.5);
    int y = 0;
    if (q == 5) y = g(2);
    int s = 0;
    { int r = cq_theta(7, 0.25); bool t = cq_theta((bool)0, 0.4);
      if (t) r = cq_theta(r, 0.2);
      if ((y >> 1) & 1) cq_phi(0.3);
      s += cq_measure(r) + cq_measure(t); }
    { int r = cq_theta(7, 0.25); bool t = cq_theta((bool)0, 0.4);
      if (t) r = cq_theta(r, 0.2);
      if ((y >> 1) & 1) cq_phi(0.3);
      s += cq_measure(r) + cq_measure(t); }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
