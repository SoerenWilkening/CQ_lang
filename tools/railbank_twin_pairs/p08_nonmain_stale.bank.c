/* p01 OUTSIDE `main`, in the house style — the shape a whole-module corpus
   sweep sees differently from a `main`-only one (two defines survive in the
   lowered module). */
#include "CQ.h"
__attribute__((noinline)) int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
