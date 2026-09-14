#include "CQ.h"
/* WELL-FORMED: TWO independent phi-carried chains in one loop. Both are self-assigned,
   so each header phi is its own barrier. Must ACCEPT. Attacks phiTracksWire's
   wire-awareness: the OTHER rail's theta sits between q's last gate and the latch. */
int main(void){ int q=cq_theta(0,0.3); int r=cq_theta(0,0.4); int s=0;
  for(int i=0;i<3;i++){ q=cq_theta(q,0.1); r=cq_theta(r,0.2); s+=cq_measure(q)+cq_measure(r); }
  return s; }
