#include "CQ.h"
/* two readers of the SAME header phi in one trip; the second is stale. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int a=cq_theta(q,0.1); int z=cq_theta(q,0.2); s+=cq_measure(a)+cq_measure(z); q=a; }
  return s; }
