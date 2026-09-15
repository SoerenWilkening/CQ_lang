/* the LEGITIMATE sibling of p01, ONE LINE apart: the bank is measured BEFORE
   the rail is re-rotated.  Both halves must ACCEPT and the streams must match —
   this is the row that proves the fence separated ORDERING and did not ban the
   shape. */
#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
