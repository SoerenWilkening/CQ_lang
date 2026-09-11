#include "CQ.h"
int main(void){ int q = cq_theta(3,0.3); int r = 5; _Bool b = 0;
  if (q == 5) r = cq_theta(5, 0.9);
  if (q == 7) b = cq_theta(0, 0.4);
  return cq_measure(q)+cq_measure(r)+(int)cq_measure(b); }
