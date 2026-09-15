#include "CQ.h"
/* R13: the undef measure outcome feeds a loop-carried classical phi. */
int main(void){ int u; int m = cq_measure(u); int q = cq_theta(0,0.3);
  for (int i = 0; i < 4; i++) { m = m + i; q = cq_theta(q, 0.1); }
  return cq_measure(q) + m; }
