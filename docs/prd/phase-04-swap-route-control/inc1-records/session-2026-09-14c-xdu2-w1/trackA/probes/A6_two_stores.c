/* Track A, clause C4 negative: TWO store sites into one bank (cell i and cell N-1-i). */
#include "CQ.h"
int main(void){ int a=5; bool b[4]={0};
  for(int i=0;i<4;++i){ if(a>=3){ b[i]=cq_theta(b[i],0.5); b[3-i]=cq_theta(b[3-i],0.25);} if(b[i]) a-=3; }
  int s=cq_measure(a); for(int i=0;i<4;++i) s+=cq_measure(b[i]); return s; }
