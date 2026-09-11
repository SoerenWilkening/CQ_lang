#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.5);
  int a = (q == 1) ? 2 : 5; int m = cq_measure(q); return m + a; }
