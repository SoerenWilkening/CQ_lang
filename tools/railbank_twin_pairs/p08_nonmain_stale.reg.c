#include "CQ.h"
__attribute__((noinline)) int slice(int seed) {
  int q = seed; cq_theta(&q, 0.5);
  int c = q;
  cq_theta(&q, 0.7);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
}
int main(void) { return slice(1); }
