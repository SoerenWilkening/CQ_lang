/* the ARRAY-FREE twin of p10. */
#include "CQ.h"
__attribute__((noinline)) int slice(int seed) {
  int q = seed; cq_theta(&q, 0.5);
  int c = q;
  int t = q + 3;
  int s = cq_measure(t);
  return s + cq_measure(c) + cq_measure(c) + cq_measure(c);
}
int main(void) { return slice(1); }
