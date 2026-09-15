/* f14 — f13's control: the SAME two banks with the stale ordering removed.
   MUST ACCEPT, or the hop has declined a whole shape rather than an ordering. */
#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int b1[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) b1[i] = cq_theta(b1[i], 0.2);
  for (int i = 0; i < 3; ++i) s += cq_measure(b1[i]);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  q = cq_theta(q, 0.7);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
