/* u1: unfolded self-controlled, straight-through = the condition register. */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); int r = q;
  if (q == 5) r = cq_theta(q, 0.9);
  return cq_measure(r); }
