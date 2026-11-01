#include "CQ.h"
/* cq-nyto (2), review c8: the caller reads the clone's i64 cell rail through an f64 view that is only
   compared, never kept: the clone's rail stays garbage and the twin uncomputes it after the view's
   clean-up (before: kept entangled, a leak at exit). */
#include <stdint.h>
#include <string.h>
__attribute__((noinline)) static int g(int64_t x, double *ip) { int64_t z = x + 3; memcpy(ip, &z, 8); return 1; }
int clone_cell_view_garbage(int64_t x0, double th) {
  int64_t x = x0; cq_theta(&x, th);
  double ip; int r = g(x, &ip);
  int q = ip > 1.0;
  return cq_measure(q) + r + (int)cq_measure(x);
}
