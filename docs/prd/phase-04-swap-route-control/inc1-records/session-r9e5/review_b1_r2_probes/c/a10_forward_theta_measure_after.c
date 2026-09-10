/* a10 — a FORWARD name on the wire, measured AFTER the select. Expect ACCEPT
   (the theta is provably post-select; the measure owns the register after). */
#include "CQ.h"
int main(void){ bool b0=0; bool b=cq_theta(b0,0.5); int a=b?2:5;
  bool c=cq_theta(b,0.3); int m=cq_measure(c); return m+cq_measure(a); }
