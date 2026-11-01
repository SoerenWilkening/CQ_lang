#include "CQ.h"
/* cq-xivx (CR §1.4 _inv<c>, rules 6, 18; probe p18 of review w2a-calls4-n1): the clone overwrites the caller's
   cell with 3*old + n, a rule-6 bijection of the old content, and the old register is dead after the call. The
   caller calls __cq_q_dbl_10_inv0(p, n, old) (t = (y' - n) * 3^-1, copy t onto old, uncompute t) and frees
   old. Main kept the old rail live at exit. */
static __attribute__((noinline)) int dbl(int *p, int n) { p[0] = p[0] * 3 + n; return n + 1; }
int inv_update_result(int a0, double t, int n) {
  int a[1] = {a0};
  cq_theta(&a[0], t);
  int k = dbl(a, n);
  return cq_measure(a[0]) + k;
}
