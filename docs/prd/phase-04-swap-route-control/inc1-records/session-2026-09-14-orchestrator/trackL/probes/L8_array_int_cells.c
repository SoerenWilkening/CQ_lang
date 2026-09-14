/* int cells instead of bool — the ABI-width axis of clause 3 */
#include "CQ.h"
int main(void){ int a=5; int b[3]={0,0,0};
  for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
