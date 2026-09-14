#include "CQ.h"
/* WELL-FORMED: the invariant seed is read only AFTER the loop. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ s+=i; } int b=cq_theta(q,0.1); return s+cq_measure(b); }
