/* P1 ROW — the Rule-13 review's F-1.  One LOOP-INVARIANT rail's name parked in
   every cell, the rail then relabelled NON-DIAGONALLY, the cells measured
   after.  Its register twin has no valid circuit and declines on every binary
   in the tree; the bank MUST decline too. */
#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
