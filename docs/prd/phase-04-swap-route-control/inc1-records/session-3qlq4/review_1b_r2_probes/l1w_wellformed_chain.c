#include "CQ.h"
/* WELL-FORMED twin: every rotation consumes the old name (chain), no aliased read */
int slice(int u){ int q=cq_theta(u,0.5); int t=q&1; int acc=0;
  for(int i=0;i<3;i++){ t=cq_theta(t,0.5); if(t==1) cq_phi(0.7); t=cq_theta(t,0.9); acc+=cq_measure(t); }
  return acc; }
int main(void){ return slice(3); }
