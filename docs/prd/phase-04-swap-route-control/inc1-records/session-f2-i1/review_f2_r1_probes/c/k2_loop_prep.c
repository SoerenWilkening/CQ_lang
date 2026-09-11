#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int r = 5; int a=0;
  for (int i=0;i<3;i++){ if (q == 5) r = cq_theta(5, 0.9); a += cq_measure(r); }
  return cq_measure(q)+a; }
