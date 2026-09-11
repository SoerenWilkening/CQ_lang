#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.3);
  _Bool c = (q == 5);
  _Bool r = 1;
  if (c) r = cq_theta(c, 0.9);
  return (int)cq_measure(r) + cq_measure(q); }
