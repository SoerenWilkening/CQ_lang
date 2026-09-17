// Track D's own customer shape: loop-INVARIANT compare, arm Ry on a DISJOINT rail.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  for (int i = 0; i < 2; i++) {
    if (q == 5) r = cq_theta(r, 0.9);
  }
  return cq_measure(q) + cq_measure(r);
}
