#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int a = (q == 5) ? 2 : 5; int m = cq_measure(q);
  return m + cq_measure(a); }
