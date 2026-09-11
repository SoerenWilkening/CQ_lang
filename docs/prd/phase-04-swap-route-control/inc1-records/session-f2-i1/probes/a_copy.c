#include "CQ.h"
int slice(int u){ int q = cq_theta(u, 0.5); int r = q;
  if (q == 0) r = cq_theta(0, 0.9);
  return cq_measure(q) + cq_measure(r); }
