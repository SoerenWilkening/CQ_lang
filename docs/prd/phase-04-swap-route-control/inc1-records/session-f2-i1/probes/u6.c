/* u6: volatile threshold so -O1 cannot fold the equality edge. */
#include "CQ.h"
int main(void){ volatile int kk = 5; int k = kk;
  int q = cq_theta(0, 0.25); int r = q;
  if (q == k) r = cq_theta(q, 0.9);
  return cq_measure(r); }
