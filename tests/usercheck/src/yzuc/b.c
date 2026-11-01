#include "CQ.h"
int f(int x0) {
  int a = x0;
  cq_theta(&a, 0.5);
  cq_theta(&a, __builtin_nan(""));   /* Ry in place on a again (CQ.h), no overwrite */
  return cq_measure(a);
}
