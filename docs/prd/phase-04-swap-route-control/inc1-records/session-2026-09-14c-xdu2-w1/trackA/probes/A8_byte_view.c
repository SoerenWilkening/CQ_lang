/* Track A, clause C1 negative: a MIXED access — a char view of an int-cell bank. */
#include "CQ.h"
int main(void){ int a=5; int b[3]={0,0,0}; volatile char sink;
  for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; }
  sink = ((char*)b)[1];
  int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s+sink; }
