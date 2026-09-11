#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.5); int acc=0;
  for (int i=0;i<4;i++){ if (q > 5) q = cq_theta(q, 0.9); }
  return cq_measure(q)+acc; }
