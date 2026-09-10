/* a08 — cast chain of depth 2 (zext then trunc); the measure names the MIDDLE
   value. Expect ACCEPT if the middle is a distinct rail; argue either way. */
#include "CQ.h"
int main(void){ bool s=0; s=cq_theta(s,0.5); int z=(int)s; bool t=(bool)(z&1);
  bool b=cq_theta(t,0.3); int m=cq_measure(z); int a=b?2:5;
  return m+cq_measure(a); }
