#include "CQ.h"
/* STALE under a COMPARE-conditioned in-place arm (the drbq shape). */
int slice(int u){ int q=cq_theta(u,0.5); int a=cq_theta(q,0.3); int r=q;
  if(u==4){ r=cq_theta(q,0.7); }
  return cq_measure(a)+cq_measure(r); }
int main(void){ return slice(4); }
