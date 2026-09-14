/* Track A, clause C6 negative: an IN-LOOP read of a cell other than the one this
   trip writes — b[0] is read on every trip while b[i] is written. */
#include "CQ.h"
int main(void){ int a=5; bool b[3]={0};
  for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[0]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
