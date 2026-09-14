/* SELF-ATTACK H-17: a bank walked by a NARROW index. If the trip count could exceed
   the index type's range the addrec wraps and injectivity is lost. */
#include "CQ.h"
int main(void){ bool b[200]={0};
  for(unsigned char i=0;i<200;++i) b[i]=cq_theta(b[i],0.5);
  int s=0; for(int i=0;i<200;++i) s+=cq_measure(b[i]); return s; }
