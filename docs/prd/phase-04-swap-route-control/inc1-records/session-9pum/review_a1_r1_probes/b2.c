#include "CQ.h"
int ext(int);
int main(void){ int acc = 0;
  for (int i = 0; i < 3; ++i) {
    _Bool b = cq_theta((_Bool)0, 0.5);
    int a = b ? i : 5;
    acc += cq_measure(a) + cq_measure(b);
  }
  return acc; }
