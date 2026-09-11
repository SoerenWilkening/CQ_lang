#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int r = 5;
  if (q == 5 || q == 9) r = cq_theta(5, 0.9);
  return cq_measure(q)+cq_measure(r); }
