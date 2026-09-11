#include "CQ.h"
int slice(_Bool u){ _Bool b0 = cq_theta(u, 0.5); _Bool b1 = 0;
  if (b0) b1 = cq_theta(b1, 0.5);
  return cq_measure(b0) + cq_measure(b1); }
