#include "CQ.h"
/* cq-xivx (CR §1.4 _inv<c>_<c'>): a clone swapping two caller cells whose old values are dead after the call:
   the group form is not built, an internal error. */
static __attribute__((noinline)) void swp(int *p) { int t = p[0]; p[0] = p[1]; p[1] = t; }
int inv_update_swap_error(int a0, double t0, int a1, double t1) {
  int a[2] = {a0, a1};
  cq_theta(&a[0], t0);
  cq_theta(&a[1], t1);
  swp(a);
  return cq_measure(a[0]) - cq_measure(a[1]);
}
