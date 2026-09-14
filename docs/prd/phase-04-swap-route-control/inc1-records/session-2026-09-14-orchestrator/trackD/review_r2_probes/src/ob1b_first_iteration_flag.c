#include "CQ.h"
/* The idiomatic spelling of ob1: a "first iteration" FLAG. The reader still executes
   exactly once; the pass sees a cycle through its block. */
int main(void){ int q=cq_theta(0,0.3); int s=0; int first=1;
  for(int i=0;i<3;i++){ if(first){ int b=cq_theta(q,0.1); s+=cq_measure(b); first=0; } else s+=1; }
  return s; }
