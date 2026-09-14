/* the array with NO initializer — the Track U (z9t1) undef-seed interaction */
#include "CQ.h"
int main(void){ int a=5; bool b[3];
  for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
