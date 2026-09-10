/* a09 — THE IN-PLACE PARENT QUESTION. The measure of b0 PRECEDES the xor, so
   M-C's G6 (no data use AFTER the site) may admit an IN-PLACE cqrt_xorc on b0's
   own rail — in which case `x` and `b0` are ONE handle and the closure's stop is
   incomplete. Measure what the pass does. */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); int m=cq_measure(b0);
  bool x=b0^1; bool b=cq_theta(x,0.3); int a=b?2:5; return m+cq_measure(a); }
