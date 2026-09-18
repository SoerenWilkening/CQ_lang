// Q3 — ht_rolled with a classical BREAK.  `-O1` if-converts it onto the latch, so
// the loop stays SINGLE-exit and IS reached by the P2 anchor walk (the anchor's own
// comment says so).  The forward gate is in the preheader (once); the `At` is the
// single exit (once).  Multiplicity should agree -- verify it does.
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
  for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); if(i>u) break; }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(void){ return slice(4); }
