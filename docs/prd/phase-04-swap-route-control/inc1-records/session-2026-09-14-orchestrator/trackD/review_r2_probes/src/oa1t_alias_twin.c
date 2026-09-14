#include "CQ.h"
/* THE ALIAS TWIN of oa1: the self-assigned chain that genuinely denotes the emitted
   circuit — the add is in place and the NEXT trip's rotation is on the post-add rail. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ q=cq_theta(q,0.1); q=q+1; s+=cq_measure(q); }
  return s; }
