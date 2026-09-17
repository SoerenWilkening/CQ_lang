/* (g) NESTED loops around the carried handle. */
#include "CQ.h"
int main(void){ int a = 5; bool b0[3];
  for (int j = 0; j < 2; ++j)
    for (int i = 0; i < 3; ++i) { if (a >= 3) b0[i] = cq_theta(b0[i], 0.5); if (b0[i]) a -= 3; }
  return cq_measure(b0[0]) + cq_measure(a); }
