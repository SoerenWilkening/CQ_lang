/* a02 — round 1's r02: cq_measure of the CHAINED PARENT name. Expect DECLINE
   ('condition measured before the control route') on the fix; ACCEPT pre-fix. */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); bool b=cq_theta(b0,0.3);
  int m=cq_measure(b0); int a=b?2:5; return m+cq_measure(a); }
