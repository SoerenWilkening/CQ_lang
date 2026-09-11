#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int m = cq_measure(q);
  for (int i = 0; i < 3; ++i) { q = q + 1; if (q > 5) cq_phi(0.3); }
  return m + cq_measure(q); }
