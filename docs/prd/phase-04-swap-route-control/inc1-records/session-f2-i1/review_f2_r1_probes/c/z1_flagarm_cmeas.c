#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.3);
  _Bool c = (q == 5);
  _Bool r = 1;
  if (c) r = cq_theta(c, 0.9);        /* alpha: rotate the FLAG in place */
  return (int)cq_measure(r) + (int)cq_measure(c) + cq_measure(q); }
