#include "CQ.h"
/* WELL-FORMED: the inner loop CARRIES the chain (self-assigned), so the inner
   header phi is the barrier even though the mint is in the outer body. */
int main(void){ int s=0; for(int i=0;i<2;i++){ int q=cq_theta(0,0.3);
  for(int j=0;j<2;j++){ q=cq_theta(q,0.1); s+=cq_measure(q); } } return s; }
