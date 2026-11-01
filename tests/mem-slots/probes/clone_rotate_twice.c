#include "CQ.h"
/* cq-peeh (CR rule 20): the clone rotates the caller's cell in place (T3 cellsRotated, no cell write) and is
   called twice. At the second call the cell's handle has no dominating source (the first call counts as a
   write for forwarding, cq-nyto): calls::noteRotatedCells reads it at run time (readSlotCells), as a load
   after the call does. mid: a flag computed from x between the calls is uncomputed before the second call
   rotates x. */
__attribute__((noinline)) static void prep1(unsigned *x, double t1) { cq_theta(x, t1); }
unsigned clone_rotate_twice(unsigned x0, double t, double p) {
  unsigned x = x0; cq_theta(&x, t);
  prep1(&x, t);
  if (x * 3u > 5u) cq_phi(p);
  prep1(&x, t);
  prep1(&x, t);
  return cq_measure(x);
}
