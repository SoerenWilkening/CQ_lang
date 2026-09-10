/* shape 4 — THE CASCADE (the user's program as it stood 2026-09-07): each step's condition depends on the previous step's outcome.
   -O1 proves `a >= 3` <=> `b0 != 0` (a is 5 or 2) and folds the second `if` INTO the first diamond:
   one region on `b0 == 0`, a TWO-instruction arm (the b1 prep + `icmp eq b1, 0`), TWO merge phis (a: 5|2, flag: (b1==0)|false),
   then `select flag, a-3, a`. */
#include "CQ.h"
int main(void){ int a = 5; int b0 = 1; int b1 = 1;
  if (a >= 3){ b0 = cq_theta(b0, 0.5); }
  if (b0 == 0) a -= 3;
  if (a >= 3){ b1 = cq_theta(b1, 0.5); }
  if (b1 == 0) a -= 3;
  return cq_measure(a) + cq_measure(b0); }
