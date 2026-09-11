/* beta, q NOT read afterwards: nothing forces M-C out of place */
#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.5); int r = q;
  if (q != 5) r = cq_theta(5, 0.9);
  r = r + 3;
  return cq_measure(r); }
