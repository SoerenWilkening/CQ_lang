#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int r = 5;
  if ((q & 1) == 1 && q > 7) r = cq_theta(5, 0.9);
  return cq_measure(q)+cq_measure(r); }
