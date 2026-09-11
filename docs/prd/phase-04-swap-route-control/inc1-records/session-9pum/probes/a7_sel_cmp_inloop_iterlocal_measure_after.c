#include "CQ.h"
int ext(int);
int main(void){ int acc = 0;
  for (int i = 0; i < 3; ++i) { int q = cq_theta(ext(i), 0.5);   /* FRESH each trip */
    int a = (q == 1) ? i : 5; acc += cq_measure(a) + cq_measure(q); }
  return acc; }
