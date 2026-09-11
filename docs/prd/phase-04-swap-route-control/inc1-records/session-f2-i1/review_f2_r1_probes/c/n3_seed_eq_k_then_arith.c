#include "CQ.h"
int main(void){ int q = cq_theta(3,0.3); int r = 5;
  if (q == 5) r = cq_theta(5, 0.9);
  int s = r + q;                      /* Q+Q on the prepped rail and the cond rail */
  return cq_measure(s); }
