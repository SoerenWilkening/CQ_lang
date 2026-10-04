#include "CQ.h"
int slice(int seed) {
  int q = seed; cq_theta(&q, 0.5);
  int r = q; cq_theta(&r, 0.7);
  int c = q;
  int s = cq_measure(c) + cq_measure(c) + cq_measure(c);
  return s + cq_measure(r);
}
int main(void) { return slice(1); }
