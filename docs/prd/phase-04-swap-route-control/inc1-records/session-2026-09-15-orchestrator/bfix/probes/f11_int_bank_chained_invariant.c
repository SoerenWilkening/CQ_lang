/* f11 — f10 at `int` cells (no storage cast anywhere). */
#include "CQ.h"
int slice(void) {
  int q = cq_theta(0, 0.3);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(q, 0.5);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
