#include "CQ.h"
/* E3 POSITION P2 — the MUST-NOT-RELABEL control. The read PRECEDES the measure in
   the body, so on trip 2 it reads an already-measured rail and on trip 1 it does not.
   Dominance FAILS (M does not dominate U), so E3 leaves it exactly as today. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int a=cq_theta(q,0.5); int m=cq_measure(q); s+=m+cq_measure(a); }
  return s; }
