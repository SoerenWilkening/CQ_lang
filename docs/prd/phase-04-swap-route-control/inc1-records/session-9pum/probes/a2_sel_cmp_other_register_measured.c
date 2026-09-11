#include "CQ.h"
int main(void){ int p = cq_theta(0, 0.7); int q = cq_theta(1, 0.5);
  int m = cq_measure(p);                  /* a DIFFERENT register */
  int a = (q == 1) ? 2 : 5; return m + a; }
