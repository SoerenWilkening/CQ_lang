/* Track A, clause C6 negative: an OVER-SIZED bank — bool b[8] walked by for(i<3),
   so cells 3..7 are never written and would read as handle 0 (a live rail). */
#include "CQ.h"
int main(void){ int a=5; bool b[8]={0};
  for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<8;++i) s+=cq_measure(b[i]); return s; }
