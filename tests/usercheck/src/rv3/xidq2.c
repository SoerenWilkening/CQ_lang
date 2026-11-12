/* cq-xidq at call depth (CR rule 12: a callee reached from a quantum arm): g's phase on the measured m is reached under y > 0. */
#include "CQ.h"
__attribute__((noinline)) static void g(int m) { if (m > 3) cq_phi(0.4); }
int f(int x0, int y0) {
  int x = x0, y = y0;
  cq_theta(&x, 0.7);
  cq_theta(&y, 0.3);
  int m = cq_measure(x);
  if (y > 0) g(m);
  return cq_measure(y);
}
