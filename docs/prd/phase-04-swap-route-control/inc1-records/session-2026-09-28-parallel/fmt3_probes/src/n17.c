#include <stdlib.h>
/* REALIZABLE rival: W = q + 1 is a separate rail OFF the inner condition's wire (q == 5);
   the source rotates W in place on q2>3 && q==5.  sink -> phi[W,6] -> select(q==5,W,6) -> simplifyWithOpReplaced -> 6 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int W = q + 1; int q2 = cq_theta(7, .4); int r = 6;
  if (q2 > 3) { if (q == 5) r = cq_theta(W, .9); else r = cq_theta(6, .9); }
  return cq_measure(r) + cq_measure(W) + cq_measure(q2); }
