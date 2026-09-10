/* a14 — the parent measured on a CLASSICALLY GUARDED side path that reaches the
   select. Expect DECLINE (reachability, the F-1b-2 shape) — an over-decline in
   the safe direction. */
#include "CQ.h"
int main(int argc,char**argv){ (void)argv; bool b0=0; b0=cq_theta(b0,0.5);
  bool b=cq_theta(b0,0.3); int m=0; if(argc>7) m=cq_measure(b0);
  int a=b?2:5; return m+cq_measure(a); }
