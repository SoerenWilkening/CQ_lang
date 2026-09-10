/* shape 2, second workaround: b is quantum before the region (an ordinary controlled Ry on a disjoint register) */
#include "CQ.h"
int main(void){ int a = 0; int b = 0;
  a = cq_theta(a, 0.5); b = cq_theta(b, 0.1);
  if (a == 0){ b = cq_theta(b, 0.5); }
  return cq_measure(a) + cq_measure(b); }
