/* a13 — the PARENT name measured AFTER the select (straight line). The widening
   must NOT decline this: the measure cannot reach the select. */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); bool b=cq_theta(b0,0.3);
  int a=b?2:5; int m=cq_measure(b0); return m+cq_measure(a); }
