/* (e) L1 — a value CLASSICAL at round 1 and TAINTED at round 2: the carried
   variable is seeded from a 6.5/4.5 merge %out produced by a PRECEDING region. */
#include "CQ.h"
int main(void){ int a = 5; bool p; bool b0[3];
  p = cq_theta(p, 0.3);
  if (p) a = 7;                       /* a's seed becomes a merge %out (round-2 taint) */
  for (int i = 0; i < 3; ++i) { if (a >= 3) b0[i] = cq_theta(b0[i], 0.5); if (b0[i]) a -= 3; }
  return cq_measure(b0[0]) + cq_measure(a); }
