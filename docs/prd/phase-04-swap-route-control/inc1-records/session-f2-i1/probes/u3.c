/* u3: self-controlled, result NOT merged (fresh r, dead on the other edge). */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); int acc = 0;
  if (q == 5) { int r = cq_theta(q, 0.9); acc = cq_measure(r); }
  return acc; }
