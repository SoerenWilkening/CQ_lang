#include <stdlib.h>
/* fmt3: a6 with literal -1, t = q ^ 3 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q ^ 3; int q2 = cq_theta(7, .4); int r = -1;
  if (q2 > 3) { if (t == -1) r = cq_theta(t, .9); else r = cq_theta(-1, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
