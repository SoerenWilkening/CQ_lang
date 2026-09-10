/* a07 — same, the measure names the i32 SOURCE q (a different register).
   Expect ACCEPT (the documented stop). */
#include "CQ.h"
int main(void){ int q=0; q=cq_theta(q,0.5); bool t=(bool)(q&1); bool b=cq_theta(t,0.3);
  int m=cq_measure(q); int a=b?2:5; return m+cq_measure(a); }
