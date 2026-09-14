#include "CQ.h"
/* STALE base under a FOLDED ANGLE SELECT (AngleSelectEmit hoists+replaces the theta). */
int slice(int u){ int q=cq_theta(u,0.5); int a=cq_theta(q,0.3);
  int r = (u==4) ? cq_theta(q,0.7) : cq_theta(q,0.2);
  return cq_measure(a)+cq_measure(r); }
int main(void){ return slice(4); }
