#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int r;
  if (q == 5) r = cq_theta(5, 0.9); else r = 5;
  return cq_measure(q)+cq_measure(r); }
