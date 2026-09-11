#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5); int t = q + 3; int m = cq_measure(q);
  int a = (t == 5) ? 2 : 5; return m + cq_measure(a) + cq_measure(t); }
