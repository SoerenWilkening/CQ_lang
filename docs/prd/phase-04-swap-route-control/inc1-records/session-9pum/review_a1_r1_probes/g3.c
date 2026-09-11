#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int p = cq_theta(1, 0.7); int m = cq_measure(q);
  if (q > 5) p = p + 3; return m + cq_measure(p); }
