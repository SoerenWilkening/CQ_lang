/* w1: alpha-reading of range_ordered -- rotate the MASK rail t under a cond on t. */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.25); int t = q & 3; int r = t;
  if (t > 2) r = cq_theta(t, 0.9);
  return cq_measure(r)+cq_measure(q); }
