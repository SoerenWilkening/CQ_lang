#include "CQ.h"
int slice(int u){ int q = cq_theta(u, 0.5); int r = 0;
  if (q == 0) r = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r); }
