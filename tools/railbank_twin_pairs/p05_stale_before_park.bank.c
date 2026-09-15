/* the rail is relabelled BEFORE it is parked, so the name written into every
   cell is ALREADY stale when the store executes.  Both halves must DECLINE —
   the register twin is the plain bd `3d8q` shape, and the bank must not launder
   it either. */
#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int r = cq_theta(q, 0.7);            /* sibling in-place Ry on q's wire */
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;   /* parks an already-relabelled name */
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(r);
}
int main(void) { return slice(1); }
