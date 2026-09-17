#include "CQ.h"
int main(void){ int a = 5; bool b0[3]; int q = cq_theta(0, 0.5);
  for (int i = 0; i < 3; ++i) { if (a >= 3) b0[(i + q) & 1] = cq_theta(b0[(i + q) & 1], 0.5); if (b0[i]) a -= 3; }
  return cq_measure(b0[0]) + cq_measure(a); }
