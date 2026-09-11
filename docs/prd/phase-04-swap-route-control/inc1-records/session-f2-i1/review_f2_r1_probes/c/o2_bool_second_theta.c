/* two independent registers; prep on the second, condition on the first */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int p = cq_theta(1,0.2); _Bool b = 0;
  if (q == 1) b = cq_theta(0, 0.9);
  return cq_measure(q)+cq_measure(p)+(int)cq_measure(b); }
