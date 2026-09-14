#include "CQ.h"
/* THE STRAIGHT-LINE ANALOGUE of oa1: `a` has a data use AFTER the add site, so M-C's
   G6 must refuse the in-place conversion. The loop form (oa1) has the SAME property,
   through the BACK EDGE. */
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.1); int d=a+1;
  int m=cq_measure(d); int e=cq_theta(a,0.2); return m+cq_measure(e); }
