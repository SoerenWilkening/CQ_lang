#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5); int s = 0;
  s += cq_measure(q); s += cq_measure(q); s += cq_measure(q);
  q = cq_theta(q, 0.9);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
