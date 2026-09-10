#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); bool t = b;
  for (int i = 0; i < 3; ++i) { if (b) cq_phi(0.9); t = cq_theta(b, 0.1); }
  return cq_measure(b) + cq_measure(t); }
