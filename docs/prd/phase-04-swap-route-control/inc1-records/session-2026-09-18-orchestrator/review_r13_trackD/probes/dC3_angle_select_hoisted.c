// The Rz-stem folded if/else ANGLE SELECT under a hoisted loop-invariant compare.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  for (int i = 0; i < 2; i++) {
    if (q == 5) cq_phi(0.3); else cq_phi(0.7);
  }
  return cq_measure(q);
}
