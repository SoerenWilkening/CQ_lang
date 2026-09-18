// Q5 — ONE hoisted rail, TWO sibling loops, NO bank (so the bank fence cannot
// speak first).  `allUsersInside` is per-loop and each loop's readers lie outside
// the other, so both should refuse.  A grant for either is a discharge at one
// loop's exit with the other loop still reading the rail.
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int s=cq_theta(u,0.7); int p=q*3;
  for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  for(int j=0;j<3;j++){ if((p>>j)&2) cq_phi(0.3); s=cq_theta(s,0.15); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r)+cq_measure(s); }
int main(void){ return slice(4); }
