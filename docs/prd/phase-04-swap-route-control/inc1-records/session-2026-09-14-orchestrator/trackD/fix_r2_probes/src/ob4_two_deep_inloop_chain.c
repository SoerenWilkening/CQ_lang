#include "CQ.h"
/* WELL-FORMED: a TWO-DEEP chain carried by the loop. The reader of the phi is not the
   wire's last gate, so phiTracksWire must look past the intermediate. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int a=cq_theta(q,0.1); q=cq_theta(a,0.2); s+=cq_measure(q); }
  return s; }
