/* tests/calls probe (cq-567j; gate 2a review unc-h1 p16-p19): a clone that only READS a caller's slot cell
 * through a pointer formal. Every rail the cell may hold at the call is used by the forward call (and read by the
 * call's item when the call has a twin): never _unc'd and freed between the store into the cell and the call. */
#include "CQ.h"
__attribute__((noinline)) static void bump(int *p, int *q) { *p += *q; }
int ro_bump(int x0, double th, int k, int r0, double tr, double p) {   /* p16: one formal written, one read */
  int x = x0; cq_theta(&x, th);
  int r = r0; cq_theta(&r, tr);
  int y = r * k;
  bump(&r, &x);
  if (y > 3) cq_phi(p);
  return cq_measure(x) + cq_measure(r);
}
__attribute__((noinline)) static void use(int *q, double p) { if (*q > 3) cq_phi(p); }
int ro_phase(int x0, double th, int k, double p) {   /* p17: no twin, a garbage cell read by the call */
  int x = x0; cq_theta(&x, th);
  int y = x + k;
  use(&y, p);
  return cq_measure(x);
}
__attribute__((noinline)) static int rd(int *q, int *r) { return *q + *r; }
int ro_result(int x0, double th, int k) {   /* p18: a quantum result (a twin re-reading both cells) */
  int x = x0; cq_theta(&x, th);
  int y = x + k;
  int z = rd(&x, &y);
  return cq_measure(z);
}
__attribute__((noinline)) static int rdm(int *q, int m) { return *q * m; }
int ro_old(int x0, double th, int k, int m) {   /* p19: the cell holds a copy of a value overwritten later */
  int x = x0; cq_theta(&x, th);
  int old = x;
  x = x + k;
  int z = rdm(&old, m);
  return cq_measure(z) + cq_measure(x);
}
