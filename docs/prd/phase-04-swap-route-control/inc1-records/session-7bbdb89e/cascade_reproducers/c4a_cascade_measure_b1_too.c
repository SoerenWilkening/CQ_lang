/* shape 4 with b1 also measured (does reading b1 change the fold?) */
#include "CQ.h"
int main(void){ int a = 5; int b0 = 1; int b1 = 1;
  if (a >= 3){ b0 = cq_theta(b0, 0.5); }
  if (b0 == 0) a -= 3;
  if (a >= 3){ b1 = cq_theta(b1, 0.5); }
  if (b1 == 0) a -= 3;
  return cq_measure(a) + cq_measure(b0) + cq_measure(b1); }
