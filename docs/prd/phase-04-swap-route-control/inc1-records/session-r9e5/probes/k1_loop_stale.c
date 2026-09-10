#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); int acc = 0;
  for (int i = 0; i < 3; ++i) { if (b) cq_phi(0.9); bool t = cq_theta(b, 0.1); acc += cq_measure(t) * 0; }
  return cq_measure(b) + acc; }
