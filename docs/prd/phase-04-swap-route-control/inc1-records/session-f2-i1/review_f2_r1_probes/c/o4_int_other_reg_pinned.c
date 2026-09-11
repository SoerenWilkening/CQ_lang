/* genuine i32 prep; an off-wire tainted register happens to equal the seed */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int t = q * 3; int r = 15;
  if (q == 5) r = cq_theta(15, 0.9);
  return cq_measure(q)+cq_measure(r)+cq_measure(t); }
