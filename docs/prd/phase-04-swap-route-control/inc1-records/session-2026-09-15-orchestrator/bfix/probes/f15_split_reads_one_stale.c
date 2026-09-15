/* f15 — RE-ATTACK: the gate sits BETWEEN two reads of the same bank.  The FIRST
   read is legitimate, the SECOND is stale.  A fence that answered per-BANK
   rather than per-READ would either over-decline the first or miss the second. */
#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  s += cq_measure(b0[0]);
  q = cq_theta(q, 0.7);
  s += cq_measure(b0[1]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
