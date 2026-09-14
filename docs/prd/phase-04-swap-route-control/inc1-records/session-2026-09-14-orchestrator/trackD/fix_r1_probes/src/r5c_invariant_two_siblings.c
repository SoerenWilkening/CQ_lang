#include "CQ.h"
/* r5 with TWO siblings in the body (the l1 shape MINUS the compare and the cq_phi). */
int slice(int u){ int q=cq_theta(u,0.5); int t=q&1; int s=0;
  for(int i=0;i<3;i++){ int b=cq_theta(t,0.5); int c=cq_theta(t,0.9); s+=cq_measure(b)+cq_measure(c); } return s; }
int main(void){ return slice(3); }
