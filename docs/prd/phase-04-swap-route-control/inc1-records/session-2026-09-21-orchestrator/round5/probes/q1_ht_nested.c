// Q1 — tu9q's OWN intended customer (ht_rolled, NO bank) put inside an OUTER loop.
// The mint `p` is outside the whole nest; the consumer is the inner body; so
// anchorForConsumer's LOut is the OUTER loop and the discharge lands at the outer
// exit, ONCE, while the inner forward gate ran once (it too is outside both).
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
  for(int o=0;o<2;o++){ for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); } r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(void){ return slice(4); }
