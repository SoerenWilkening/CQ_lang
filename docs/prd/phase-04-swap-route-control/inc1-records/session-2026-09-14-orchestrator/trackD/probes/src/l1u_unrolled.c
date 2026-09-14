#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int t=q&1; int acc=0;
  { int b=cq_theta(t,0.5); if(b==1) cq_phi(0.7); int c=cq_theta(t,0.9); acc+=cq_measure(c); }
  { int b=cq_theta(t,0.5); if(b==1) cq_phi(0.7); int c=cq_theta(t,0.9); acc+=cq_measure(c); }
  { int b=cq_theta(t,0.5); if(b==1) cq_phi(0.7); int c=cq_theta(t,0.9); acc+=cq_measure(c); }
  return acc; }
int main(void){ return slice(3); }
