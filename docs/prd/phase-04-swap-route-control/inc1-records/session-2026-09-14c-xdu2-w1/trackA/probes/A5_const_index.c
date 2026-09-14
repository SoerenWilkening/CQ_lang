/* Track A, clause C2' negative: a CONSTANT cell index inside the loop — every trip
   writes cell 0, so a later trip's seed load reads a previously-stored handle. */
#include "CQ.h"
int main(void){ int a=5; bool b[3]={0};
  for(int i=0;i<3;++i){ if(a>=3) b[0]=cq_theta(b[0],0.5); if(b[0]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
