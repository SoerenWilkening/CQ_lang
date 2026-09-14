/* SELF-ATTACK H-1: the bank's walk loop is NESTED inside an outer loop, so every
   cell is written TWICE and a later OUTER trip's seed load reads a stored HANDLE —
   exactly the hazard C2' exists to prevent, one activation level up. */
#include "CQ.h"
int main(void){ bool b[3]={0};
  for(int k=0;k<2;++k) for(int i=0;i<3;++i) b[i]=cq_theta(b[i],0.5);
  int s=0; for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
