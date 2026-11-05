/* tests/eff-invert probes (cq-w2b-invert): a classical loop inside a cq_invert region (rule 17: trips in
 * reverse order; 126's shape with a second register and a trip-dependent phase angle). */
#include "CQ.h"
int p_cloop(int x0, double tx, int r0, const double *th, int n, int k, double ph) {
  int x = x0;
  cq_theta(&x, tx);
  int r = r0;
  cq_invert_begin();
  for (int i = 0; i < n; i++) {
    if (x > k + 2 * i) {
      cq_theta(&r, th[i]);
      cq_phi(ph * i);
    }
    if ((x ^ i) & 1) cq_phi(th[i]);
  }
  cq_invert_end();
  return cq_measure(r) + cq_measure(x);
}
