#include "CQ.h"
/* oa1 with an ADDITIONAL later use of `a` INSIDE the body. If this goes out-of-place
   while oa1 goes in-place, the loop path's "later use" clause exists but does not
   count the rail phi's LATCH INCOMING. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int a=cq_theta(q,0.1); int d=a+1; s+=cq_measure(d);
    int e=cq_theta(a,0.2); s+=cq_measure(e); q=a; }
  return s; }
