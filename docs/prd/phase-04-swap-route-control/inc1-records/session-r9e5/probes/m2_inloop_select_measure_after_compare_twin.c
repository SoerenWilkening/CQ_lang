#include "CQ.h"
int main(void){ int b = cq_theta(0, 0.5); int acc = 0;
  for (int i = 0; i < 3; ++i) { int a = (b == 1) ? i : 5; acc += cq_measure(a) + cq_measure(b); }
  return acc; }
