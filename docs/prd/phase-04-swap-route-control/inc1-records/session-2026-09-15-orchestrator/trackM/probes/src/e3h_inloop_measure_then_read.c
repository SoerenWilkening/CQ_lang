#include "CQ.h"
/* E3 POSITION P1: the measure is INSIDE the loop and the read FOLLOWS it in the same
   body. `DT.dominates(M,U)` holds; `provablyBefore(M,U)` does NOT (the back edge
   makes M reachable from U). This probe is the one that separates plain dominance
   from WireWalk::provablyBefore, and it is why E3 must state which it uses. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int m=cq_measure(q); int a=cq_theta(q,0.5); s+=m+cq_measure(a); }
  return s; }
