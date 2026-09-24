/* bd xdu2.1 (Track B): a register-free cq_phi between park and read — diagonal,
   deleted as a global phase; must NOT be a stale read. */
#include "CQ.h"
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b[i] = q;
  cq_phi(0.4);
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
