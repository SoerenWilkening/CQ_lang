#include "CQ.h"
int ext(int);
int main(void){ int acc = 0;
  for (int i = 0; i < 3; ++i) {
    _Bool b = cq_theta((_Bool)0, 0.5);
    if (b) cq_phi(0.3);
    acc += cq_measure(b) + ext(i);
  }
  return acc; }
