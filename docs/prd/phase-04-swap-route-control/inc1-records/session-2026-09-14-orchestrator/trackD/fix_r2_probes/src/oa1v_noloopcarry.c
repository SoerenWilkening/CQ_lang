#include "CQ.h"
/* oa1 with NO loop carry (q re-minted each trip): `a` has NO use after the add at all,
   so the in-place conversion is CORRECT here. The control for oa1. */
int main(void){ int s=0;
  for(int i=0;i<3;i++){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.1); int d=a+1; s+=cq_measure(d); }
  return s; }
