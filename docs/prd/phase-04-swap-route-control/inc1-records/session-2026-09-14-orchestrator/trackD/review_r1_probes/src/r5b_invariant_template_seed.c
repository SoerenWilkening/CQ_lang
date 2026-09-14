#include "CQ.h"
/* r5 with the loop-invariant seed a TEMPLATE-minted rail. */
int slice(int u){ int q=cq_theta(u,0.5); int t=q&1; int s=0;
  for(int i=0;i<3;i++){ int b=cq_theta(t,0.1); s+=cq_measure(b); } return s; }
int main(void){ return slice(3); }
