#include "CQ.h"
/* WELL-FORMED: a loop, then a straight-line chain on a name the loop never touched. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int r=cq_theta(0,0.4); s+=cq_measure(r); }
  int b=cq_theta(q,0.1); return s+cq_measure(b); }
