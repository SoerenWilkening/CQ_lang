/* v2: unfolded self-controlled, DERIVED condition (q+1 > 5), same wire. */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); int r = q; int t = q + 1;
  if (t > 5) r = cq_theta(q, 0.9);
  return cq_measure(r); }
