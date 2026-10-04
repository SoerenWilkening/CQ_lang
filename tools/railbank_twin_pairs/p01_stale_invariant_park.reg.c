/* the ARRAY-FREE twin: the same stale read with no memory anywhere. */
#include "CQ.h"
int slice(int seed) {
  int q = seed; cq_theta(&q, 0.5);
  int c = q;
  cq_theta(&q, 0.7);
  return cq_measure(c) + cq_measure(c) + cq_measure(c) + cq_measure(q);
}
int main(void) { return slice(1); }
