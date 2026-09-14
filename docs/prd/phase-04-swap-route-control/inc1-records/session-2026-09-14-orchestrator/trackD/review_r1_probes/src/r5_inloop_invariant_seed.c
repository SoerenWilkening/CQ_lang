#include "CQ.h"
/* GENUINELY STALE: `q` is loop-INVARIANT, so trip 2's `cq_theta(q,.1)` reads a name the
   trip-1 gate already moved past. Leg 2 with a NON-PHI seed (IMPL_D §9 item 3). */
int main(void){ int q=cq_theta(0,0.3); int s=0; for(int i=0;i<3;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); } return s; }
