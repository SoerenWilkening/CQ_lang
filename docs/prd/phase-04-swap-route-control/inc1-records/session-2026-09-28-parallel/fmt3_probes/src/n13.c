#include <stdlib.h>
/* fmt3: a GENUINELY realizable rival: the inner condition reads q, the arm rotates t = q/4 (off the inner wire) */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (q == 20) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
