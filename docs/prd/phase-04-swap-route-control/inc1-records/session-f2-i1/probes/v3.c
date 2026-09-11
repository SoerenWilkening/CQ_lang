/* v3: unfolded self-controlled, arm rotates the DERIVED alias t, cond reads q. */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); int t = q + 1; int r = t;
  if (q > 5) r = cq_theta(t, 0.9);
  return cq_measure(r); }
