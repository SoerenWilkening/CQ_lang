#include "CQ.h"
/* ob1 with the measurement moved AFTER the loop. */
int main(void){ int q=cq_theta(0,0.3); int b=0; int s=0;
  for(int i=0;i<3;i++){ if(i==0) b=cq_theta(q,0.1); else s+=1; }
  return s+cq_measure(b); }
