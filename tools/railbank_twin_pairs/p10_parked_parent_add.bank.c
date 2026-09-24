/* bd xdu2.1 (Track B): q parked, then `t = q + 3` (the M-C late in-place
   candidate on q), then the cells measured. The add MUST stay out of place. */
#include "CQ.h"
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  int t = q + 3;
  s += cq_measure(t);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s;
}
int main(void) { return slice(1); }
