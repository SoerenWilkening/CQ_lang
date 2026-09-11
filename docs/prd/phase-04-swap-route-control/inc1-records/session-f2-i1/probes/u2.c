/* u2: unfolded self-controlled, straight-through = the literal 5. */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); int r = 5;
  if (q == 5) r = cq_theta(q, 0.9);
  return cq_measure(r); }
