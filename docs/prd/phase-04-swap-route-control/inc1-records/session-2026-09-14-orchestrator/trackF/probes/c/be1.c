/* Track F — is a BOTH-EDGE pin reachable from plain C at -O1?  `t` is provably 0
   on both edges of the guard. */
#include <stdbool.h>
int main(void){ int q = cq_theta(3, 0.3); int t = q & 0; int r = 0;
  if (q == 5) r = cq_theta(0, 0.9);
  return (int)cq_measure(r) + (int)cq_measure(t) + (int)cq_measure(q); }
