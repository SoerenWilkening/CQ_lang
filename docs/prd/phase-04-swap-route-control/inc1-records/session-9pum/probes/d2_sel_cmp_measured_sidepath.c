#include "CQ.h"
int ext(int);
int main(void){ int q = cq_theta(0, 0.5); int s = 0;
  if (ext(1)) s = cq_measure(q);          /* classically guarded side path */
  int a = (q == 1) ? 2 : 5; return s + a; }
