#include "CQ.h"
int main(void){ int u = 0; int m = cq_measure(u); int q = cq_theta(0,0.3);
  switch (m) { case 0: q = cq_theta(q,0.5); break; case 1: q = cq_theta(q,0.7); break; default: q = cq_theta(q,0.9); }
  return cq_measure(q); }
