#include "CQ.h"
/* GENUINELY STALE, one level in: the seed is minted in the OUTER body and the
   reader is in the INNER loop, so inner trip 2 reads a name inner trip 1 moved. */
int main(void){ int s=0; for(int i=0;i<2;i++){ int q=cq_theta(0,0.3);
  for(int j=0;j<2;j++){ int b=cq_theta(q,0.1); s+=cq_measure(b); } } return s; }
