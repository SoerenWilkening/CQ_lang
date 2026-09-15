#include "CQ.h"
/* E3 P4 TWIN — the same program with the post-measure read spelled as `m`. This is
   what E3 rewrites e3k into; its verdict/stream on the ORACLE is E3's target. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q);
  if (m == 5) cq_phi(0.3);
  return m; }
