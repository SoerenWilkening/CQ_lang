// ISOLATING CONTROL for x3: the same rotation of `q`, moved AFTER the loop, so
// the parent holds still across [mint, reversal]. This is `dD1` at K=2 and it
// is the cleared composition instance.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.1);
  return cq_measure(q) + cq_measure(r);
}
