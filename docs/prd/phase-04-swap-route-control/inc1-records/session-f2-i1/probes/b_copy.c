/* b_copy: the BETA rival of the owner's prep -- b1 starts as a COPY of b0. */
#include "CQ.h"
int slice(_Bool u){ _Bool b0 = cq_theta(u, 0.5); _Bool b1 = b0;
  if (b0) b1 = cq_theta(0, 0.5);
  return cq_measure(b0) + cq_measure(b1); }
