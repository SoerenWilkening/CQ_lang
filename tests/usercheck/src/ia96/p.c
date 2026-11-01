#include "CQ.h"
int f(int x0, double t) {
  int x = x0;
  cq_theta(&x, 0.5);
  int z = 0;
  cq_theta(&z, __builtin_nan(""));
  int r = 7;
  if (x & 1) { r = 0; cq_theta(&r, t); }
  (void)r; return cq_measure(x);
}
