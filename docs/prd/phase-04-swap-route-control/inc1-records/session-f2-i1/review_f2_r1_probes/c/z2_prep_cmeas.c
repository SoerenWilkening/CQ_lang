#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.3);
  _Bool c = (q == 5);
  _Bool r = 1;
  if (c) r = cq_theta(1, 0.9);        /* genuine prep twin */
  return (int)cq_measure(r) + (int)cq_measure(c) + cq_measure(q); }
