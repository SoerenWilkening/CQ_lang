/* alpha unfolded via an OPAQUE threshold: cannot fold arg-0 */
#include "CQ.h"
int thr(void);
int slice(int u){ int q = cq_theta(u,0.5); int k = thr(); int r = k;
  if (q == k) r = cq_theta(q, 0.9);
  return cq_measure(q)+cq_measure(r); }
