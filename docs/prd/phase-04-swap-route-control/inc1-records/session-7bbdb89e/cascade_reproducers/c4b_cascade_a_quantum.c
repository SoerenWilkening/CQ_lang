/* shape 4 with `a` a QUANTUM register (so -O1 cannot prove a >= 3 <=> b0 != 0 by constant folding): an ONWARD region whose condition reads the first merge's %out */
#include "CQ.h"
int main(void){ int a0 = 5; int a = cq_theta(a0, 0.2); int b0 = 1; int b1 = 1;
  if (a >= 3){ b0 = cq_theta(b0, 0.5); }
  if (b0 == 0) a -= 3;
  if (a >= 3){ b1 = cq_theta(b1, 0.5); }
  if (b1 == 0) a -= 3;
  return cq_measure(a) + cq_measure(b0) + cq_measure(b1); }
