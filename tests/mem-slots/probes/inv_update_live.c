#include "CQ.h"
/* cq-xivx (CR rule 6 Dead): the old register is measured after the call (it is not dead), so the caller
   calls no _inv clone and keeps it. */
static __attribute__((noinline)) void dbl(int *p, int n) { p[0] = p[0] * 3 + n; }
int inv_update_live(int a0, double t, int n) {
  int a[1] = {a0};
  cq_theta(&a[0], t);
  int x = a[0];
  dbl(a, n);
  return cq_measure(a[0]) + cq_measure(x);
}
