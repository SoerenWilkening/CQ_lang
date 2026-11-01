#include "CQ.h"
#include <stdbool.h>
/* cq-r7-b7 (CR rules 5, 14; 176): a classically bounded sub-loop whose quantum values die within the parent's
   trip (value(x): an accumulator read by the oracle flag only) is reversed inside that trip, after the flag's
   kickback and before the next layer of Ry rotates the cells it read. */
static int value(int nq, const bool *x) { int v = 0; for (int i = 0; i < nq; i++) v |= x[i] << i; return v; }
int t_grover(int nq, int target, int iters, double t) {
  nq &= 3; iters &= 3;
  bool x[4];
  for (int i = 0; i < nq; i++) { x[i] = 0; cq_theta(&x[i], t); }
  for (int r = 0; r < iters; r++) {
    if (value(nq, x) == target) cq_phi(3.0);
    for (int i = 0; i < nq; i++) cq_theta(&x[i], -t);
  }
  int m = 0;
  for (int i = 0; i < nq; i++) m |= cq_measure(x[i]) << i;
  return m;
}
