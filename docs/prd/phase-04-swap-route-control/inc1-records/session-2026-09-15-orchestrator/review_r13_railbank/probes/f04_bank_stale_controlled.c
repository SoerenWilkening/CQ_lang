#include <stdbool.h>
/* the relabelling gate is a CONTROLLED Ry emitted by a region, not a bare theta */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  bool c = cq_theta(seed, 0.3);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  if (c) q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q) + cq_measure(c);
}
int main(void) { return slice(1); }
