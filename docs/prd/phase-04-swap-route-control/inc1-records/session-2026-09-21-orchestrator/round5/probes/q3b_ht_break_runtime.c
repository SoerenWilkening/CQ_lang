// Q3b — q3 corrected.  In q3 `main` passed the literal 4, `-O1` const-propagated it
// into `slice`, and `i > u` folded to FALSE: the break was DELETED before the pass
// ever saw it, so q3 measured a loop with no break at all.  (A probe-design trap
// worth recording: every round-3 probe calls `slice(4)`.)  Here the bound comes from
// `argc`, so the break SURVIVES and `-O1` if-converts it onto the LATCH -- the
// single-exit `break` the anchor's own comment says IS reached by the P2 walk.
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
  for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); if(i>u) break; }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(int argc, char **argv){ (void)argv; return slice(argc); }
