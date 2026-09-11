#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.5); int r = 5;
  switch (q) { case 1: r = cq_theta(q,0.9); break; case 2: r = cq_theta(q,0.3); break; }
  return cq_measure(q)+cq_measure(r); }
