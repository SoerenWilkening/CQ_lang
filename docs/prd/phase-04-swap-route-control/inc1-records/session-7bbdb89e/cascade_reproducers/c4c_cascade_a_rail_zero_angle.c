/* shape 4, the smallest change that keeps `a = 5` and the cascade as written: give `a` a rail with a ZERO-angle Ry
   (identity rotation) so -O1 can no longer constant-fold `a >= 3` into `b0 != 0`. */
#include "CQ.h"
int main(void){ int a = cq_theta(5, 0.0); int b0 = 1; int b1 = 1;
  if (a >= 3){ b0 = cq_theta(b0, 0.5); }
  if (b0 == 0) a -= 3;
  if (a >= 3){ b1 = cq_theta(b1, 0.5); }
  if (b1 == 0) a -= 3;
  return cq_measure(a) + cq_measure(b0) + cq_measure(b1); }
