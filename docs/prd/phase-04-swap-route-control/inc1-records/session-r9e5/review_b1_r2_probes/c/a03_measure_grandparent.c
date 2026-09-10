/* a03 — chain of THREE, the measure names the GRANDPARENT. Expect DECLINE
   (the backward walk must not stop at depth 1). */
#include "CQ.h"
int main(void){ bool g=0; g=cq_theta(g,0.2); bool p=cq_theta(g,0.4);
  bool b=cq_theta(p,0.6); int m=cq_measure(g); int a=b?2:5;
  return m+cq_measure(a); }
