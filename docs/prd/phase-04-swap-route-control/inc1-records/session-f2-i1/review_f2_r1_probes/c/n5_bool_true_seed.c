#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); _Bool b = 1;
  if (q == 1) b = cq_theta(1, 0.9);
  return cq_measure(q) + (int)cq_measure(b); }
