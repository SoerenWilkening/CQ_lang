// Same, ROLLED: measure per trip, hoisted loop-invariant compare.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int s = 0;
  for (int i = 0; i < 2; i++) {
    s += cq_measure(q);
    if (q == 5) r = cq_theta(r, 0.9);
  }
  return s + cq_measure(r);
}
