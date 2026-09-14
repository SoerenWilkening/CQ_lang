#include "CQ.h"
/* The CONTROL for ob1: the guard is a RUNTIME condition that can hold on many trips,
   so the reader genuinely can stale itself. Must DECLINE on both readings. */
int main(int argc, char **argv){ (void)argv; int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ if(i<argc){ int b=cq_theta(q,0.1); s+=cq_measure(b); } else s+=1; }
  return s; }
