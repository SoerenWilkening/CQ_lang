#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int t = q + 3; int m = cq_measure(q);
  if (t > 3) cq_phi(0.3); return m + cq_measure(t); }
