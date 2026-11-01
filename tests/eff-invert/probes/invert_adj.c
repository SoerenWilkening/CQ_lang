/* tests/eff-invert probes (cq-w2b-invert): a clone call inside a cq_invert region is its _adj clone
 * (rule 17: clones as _adj), whose body is the clone's adjoint (lowerAdjointBody). */
#include "CQ.h"
__attribute__((noinline)) static void ph(int y, int k, double t, double u, double v) {
  if (y > k) cq_phi(t);
  if (y == k + 1) cq_phi(u);
  cq_phi(v);
}
int p_adj(int y0, double ty, int k, double t, double u, double v) {
  int y = y0;
  cq_theta(&y, ty);
  ph(y, k, t, u, v);
  cq_invert_begin();
  ph(y, k, t, u, v);
  cq_invert_end();
  return cq_measure(y);
}
