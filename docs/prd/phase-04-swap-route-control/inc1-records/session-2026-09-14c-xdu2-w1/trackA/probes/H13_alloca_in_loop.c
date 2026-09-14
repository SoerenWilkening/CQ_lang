/* SELF-ATTACK H-13: a NON-STATIC bank object — the array is declared inside the
   outer loop body, so every outer trip is a FRESH object and "the bank" is not one
   object at all. */
#include "CQ.h"
int main(void){ int s=0;
  for(int k=0;k<2;++k){ bool b[3]={0};
    for(int i=0;i<3;++i) b[i]=cq_theta(b[i],0.5);
    for(int i=0;i<3;++i) s+=cq_measure(b[i]); }
  return s; }
