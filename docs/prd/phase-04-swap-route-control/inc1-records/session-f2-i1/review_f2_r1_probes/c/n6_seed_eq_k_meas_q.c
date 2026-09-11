#include "CQ.h"
int main(void){ int q = cq_theta(3,0.3); int r = 5;
  if (q == 5) r = cq_theta(5, 0.9);
  r = r + 3;                          /* in-place? on the prepped rail */
  return cq_measure(q)+cq_measure(r); }
