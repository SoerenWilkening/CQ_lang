/* shape 3 with `int b0`: -O1 keeps `icmp eq i32 %1, 0`, the 4.4 select merge mints the flag from it */
#include "CQ.h"
int main(void){ int a = 5; int b0 = 1;
  if (a >= 3){ b0 = cq_theta(b0, 0.5); }
  if (b0 == 0) a -= 3;
  return cq_measure(a) + cq_measure(b0); }
