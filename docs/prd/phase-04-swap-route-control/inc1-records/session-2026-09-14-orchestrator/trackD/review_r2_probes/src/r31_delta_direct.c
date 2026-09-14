#include "CQ.h"
/* DELTA-SCOPE, the DIRECT sub-case: reader of a round-1-tainted name whose
   staler is a direct reader of the round-2 rail. Measures only, NO compare on
   the rail (the fence that claimed both of the implementer's probes). */
int ext_f(int a);
int slice(void){
  int q = cq_theta(0, 0.5);
  int y = 5; if (q > 5) y = ext_f(7);
  int rec = cq_theta(y, 0.25);
  int s   = cq_theta(y, 0.6);        /* stales rec's record, AFTER rec read it */
  return cq_measure(rec) + cq_measure(s) + cq_measure(q);
}
int main(void){ return slice(); }
