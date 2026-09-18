// Q4 — ht_rolled where the hoisted rail `p` is ALSO read AFTER the loop.
// `allUsersInside(V, L)` -- the conjunct the clause calls "the clause's SUBJECT,
// not conservatism" -- must refuse.  The measured control for that conjunct.
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
  for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r)+cq_measure(p); }
int main(void){ return slice(4); }
