/* shape 2, one-character workaround: seed 1 != the compare constant 0 */
#include "CQ.h"
int main(void){ int a = 0; int b = 1;
  a = cq_theta(a, 0.5);
  if (a == 0){ b = cq_theta(b, 0.5); }
  return cq_measure(a) + cq_measure(b); }
