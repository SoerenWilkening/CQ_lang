// ISOLATING CONTROL for x6: same out-of-place post-loop consumer, moved BEFORE
// the trailing rotation.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  int u = t * 3;
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + cq_measure(u);
}
