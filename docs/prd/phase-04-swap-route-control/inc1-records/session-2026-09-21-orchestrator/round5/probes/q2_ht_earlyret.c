// Q2 — ht_rolled with an EARLY RETURN inside the loop: two exit DESTINATIONS, so
// `Loop::getUniqueExitBlock()` is null and `loopExitDischargePoint` refuses.  The
// (ii-d) clause should then not grant at all.  If it grants anyway, the anchor
// returns nullptr and the rail leaks with conjunct (1) already silenced.
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
  for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1);
                        if(u>9 && i==1) return cq_measure(r); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(void){ return slice(4); }
