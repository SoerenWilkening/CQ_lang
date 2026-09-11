#include "CQ.h"
int ext(int);
int main(void){ int acc = 0;
  for (int i = 0; i < 3; ++i) {
    if (ext(i)) { int q = cq_theta(0, 0.5);    /* guarded, but the ONLY def */
      int a = (q == 1) ? i : 5;
      acc += cq_measure(a) + cq_measure(q); } }
  return acc; }
