#include <stdlib.h>
/* fmt3: the drbq.13 angle-select counter-example (different angles) nested in a region */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .3); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
