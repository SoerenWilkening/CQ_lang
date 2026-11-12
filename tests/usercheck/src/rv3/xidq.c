/* cq-xidq (CR rule 12, §6 global phases, rule 2's static collapse): x is measured on the c path only, so after the
 * join x > 3 is quantum and the phase under (c && x > 3) is rz_i1 under a quantum predicate, never global. */
#include "CQ.h"
int f(int x0, int c) {
  int x = x0;
  cq_theta(&x, 0.7);
  int m = 0;
  if (c) m = cq_measure(x);
  int y = m + c;
  cq_theta(&y, 0.3);
  if (c && x > 3) cq_phi(0.4);
  return cq_measure(y);
}
