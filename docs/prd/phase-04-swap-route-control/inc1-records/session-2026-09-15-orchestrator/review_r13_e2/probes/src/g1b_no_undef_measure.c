#include "CQ.h"
/* R13: does E2's preemption removal DISARM LiteralIntegrity GUARD 1? One `undef`
   double reaching TWO emitted gate slots, beside an undef classical measure.
   ORACLE: dies at the measure. SUBJECT: must reach GUARD 1 and fire (D->D, new string). */
int main(void){ double a;  int q = cq_theta(0, a); int r = cq_theta(0, a);
  return cq_measure(q) + cq_measure(r); }
