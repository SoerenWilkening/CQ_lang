#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5);
  cq_invert_begin();
  if (q == 5) cq_phi(0.7);
  cq_invert_end();
  return cq_measure(q); }
