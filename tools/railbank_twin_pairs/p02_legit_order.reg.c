#include "CQ.h"
int slice(int seed) {
  int q = seed; cq_theta(&q, 0.5);
  int c = q;
  int s = cq_measure(c) + cq_measure(c) + cq_measure(c);
  cq_theta(&q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
