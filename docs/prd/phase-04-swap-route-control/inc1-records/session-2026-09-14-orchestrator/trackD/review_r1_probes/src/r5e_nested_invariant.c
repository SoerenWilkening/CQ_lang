#include "CQ.h"
/* r5 hoisted one level: the invariant seed is outside BOTH loops. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<2;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); } 
  for(int j=0;j<2;j++){ int c=cq_theta(q,0.2); s+=cq_measure(c); } return s; }
