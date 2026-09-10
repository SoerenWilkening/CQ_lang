#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); int acc = 0;
  for (int i = 0; i < 3; ++i) { int a = b ? 2 + i : 5; acc += cq_measure(a); bool t = cq_theta(b, 0.1); acc += cq_measure(t) * 0; }
  return acc + cq_measure(b); }
