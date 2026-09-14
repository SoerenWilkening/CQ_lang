#include "CQ.h"
/* OVER-ACCEPT probe (IMPL_D §9 item 2 / the fix's own attack-surface item 2):
   phiTracksWire's `Stales` counts ONLY cq_theta, never the dtzb in-place add/xor.
   The phi carries `a`, but `d = a+1` may move the wire past it. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int a=cq_theta(q,0.1); int d=a+1; s+=cq_measure(d); q=a; }
  return s; }
