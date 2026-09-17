// The HAND-UNROLLED twin of dD1 (K=2). The rolled/unrolled byte-identity that is
// this project's strongest witness should hold; measure whether it does.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  if (t == 1) r = cq_theta(r, 0.9);
  if (t == 1) r = cq_theta(r, 0.9);
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
