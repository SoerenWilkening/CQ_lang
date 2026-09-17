/* (f) A GENUINE ITERATION-LOCAL TEMP: defined in the loop, USED in the loop (so
   -O1 cannot sink it out) and READ AFTER the loop.  That is (c3)'s own subject
   and the exemption must NOT reach it — the chain is {phi, latch}, not the
   operand cone. */
#include "CQ.h"
int main(void){ int a = 5; bool b0[3]; int q = cq_theta(0, 0.7); int t = 0;
  for (int i = 0; i < 3; ++i) {
    t = (q >> i) & 1;
    if (a >= 3) b0[i] = cq_theta(b0[i], 0.5);
    if (b0[i]) a -= 3 + t;
  }
  return cq_measure(b0[0]) + cq_measure(a) + cq_measure(t); }
