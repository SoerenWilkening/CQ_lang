/* a06 — the parent is a TRUNC of an i32 register; the measure names the trunc
   result. Expect DECLINE (same fresh rail the theta rotates in place). */
#include "CQ.h"
int main(void){ int q=0; q=cq_theta(q,0.5); bool t=(bool)(q&1); bool b=cq_theta(t,0.3);
  int m=cq_measure(t); int a=b?2:5; return m+cq_measure(a); }
