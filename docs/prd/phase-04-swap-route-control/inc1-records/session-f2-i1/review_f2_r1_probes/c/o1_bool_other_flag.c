/* genuine bool prep + an UNRELATED tainted i1 in the function (off the cond wire) */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); _Bool other = (q > 9); _Bool b = 0;
  if (q == 1) b = cq_theta(0, 0.9);
  return cq_measure(q) + (int)cq_measure(b) + (int)cq_measure(other); }
