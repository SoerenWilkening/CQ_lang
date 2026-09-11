#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int t = q * 5; int m = cq_measure(t);
  int a = (q == 5) ? 2 : 5; return m + cq_measure(a) + cq_measure(q); }
