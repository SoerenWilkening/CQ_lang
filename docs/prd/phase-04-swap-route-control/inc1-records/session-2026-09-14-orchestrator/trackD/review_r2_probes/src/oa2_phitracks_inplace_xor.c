#include "CQ.h"
/* same with XOR. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int a=cq_theta(q,0.1); int d=a^1; s+=cq_measure(d); q=a; }
  return s; }
