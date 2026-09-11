/* alpha: rotate the CONDITION'S OWN register in place, both arms -> angle select */
#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.5);
  if (q == 5) q = cq_theta(q, 0.9); else q = cq_theta(q, 0.3);
  return cq_measure(q); }
