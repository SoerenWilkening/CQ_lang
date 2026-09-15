#include <stdbool.h>
int slice(int seed) {
  bool q = cq_theta(seed, 0.5);
  bool b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
