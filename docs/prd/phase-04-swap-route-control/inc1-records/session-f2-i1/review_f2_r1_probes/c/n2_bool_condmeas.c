#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); _Bool c = (q == 1); _Bool b = 0;
  if (c) b = cq_theta(0, 0.9);
  return cq_measure(q) + (int)cq_measure(b) + (int)cq_measure(c); }
