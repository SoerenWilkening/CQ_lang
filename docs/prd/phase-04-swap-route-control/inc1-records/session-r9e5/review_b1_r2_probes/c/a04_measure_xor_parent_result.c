/* a04 — the parent is an OUT-OF-PLACE xor template; the measure names the XOR
   RESULT (the collected non-theta tainted parent). Expect DECLINE: the theta
   rides the xor's fresh rail, so that name IS the register. */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); bool x=b0^1; bool b=cq_theta(x,0.3);
  int m=cq_measure(x); int a=b?2:5; return m+cq_measure(a); }
