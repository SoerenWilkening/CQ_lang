/* a05 — same shape, the measure names the xor's SOURCE b0 (a DIFFERENT rail
   after an out-of-place template). Expect ACCEPT — the stop rule's own pin. */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); bool x=b0^1; bool b=cq_theta(x,0.3);
  int m=cq_measure(b0); int a=b?2:5; return m+cq_measure(a); }
