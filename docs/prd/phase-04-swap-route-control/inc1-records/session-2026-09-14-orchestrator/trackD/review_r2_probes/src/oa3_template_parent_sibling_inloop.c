#include "CQ.h"
/* the r903 parity gap: the wire's ancestry crosses a TEMPLATE op, and a sibling gate
   hangs off the template parent inside the loop. */
int main(void){ int q=cq_theta(0,0.3); int t=q&1; int u=cq_theta(t,0.4); int s=0;
  for(int i=0;i<3;i++){ u=cq_theta(u,0.1); int w=cq_theta(t,0.5); s+=cq_measure(u)+cq_measure(w); }
  return s; }
