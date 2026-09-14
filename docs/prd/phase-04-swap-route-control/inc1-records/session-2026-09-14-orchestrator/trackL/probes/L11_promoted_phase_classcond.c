/* same but the prep condition is CLASSICAL (i) — no region at all; control */
#include "CQ.h"
int main(void){ int q=0; q=cq_theta(q,0.3);
  for(int i=0;i<3;++i){ bool t=0; t=cq_theta(t,0.5); if(t) cq_phi(0.5); }
  return cq_measure(q); }
