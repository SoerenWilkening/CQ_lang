/* CR rule 17 (a flush point splits the region): a template made in the region before a measurement and read after it
 * is uncomputed before the measurement and made again after it, so its compute and its uncompute never straddle the
 * flush point (the replayed phase predicate reads x * 3, not 0). */
#include "CQ.h"
int p_flush(int x0, double tx, int y0, double ty, int k, double p) {
  int x = x0; cq_theta(&x, tx);
  int y = y0; cq_theta(&y, ty);
  cq_invert_begin();
  int s = x * 3;
  int m = cq_measure(y);
  if (s == k + m) cq_phi(p);
  cq_invert_end();
  return cq_measure(x) + m;
}
