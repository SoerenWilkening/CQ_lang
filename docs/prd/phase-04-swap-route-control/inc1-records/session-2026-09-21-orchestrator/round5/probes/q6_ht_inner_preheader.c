// Q6 — the rail is minted in the INNER loop's PREHEADER (so it REPEATS once per
// OUTER trip) and read by the inner body.  anchorForConsumer's LOut is the INNER
// loop, whose exit block ALSO repeats once per outer trip.  The anchor's comment
// says §2.9's `blockCanRepeat(At)` must refuse a repeating At -- verify, and check
// whether the (ii-d) grant then leaks silently or declines.
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int o=0;o<2;o++){ int p=q*(o+3);
    for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); }
    r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(void){ return slice(4); }
