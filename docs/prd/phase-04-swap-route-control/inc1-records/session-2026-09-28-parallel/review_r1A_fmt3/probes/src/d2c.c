#include <stdlib.h>
/* r1A: a6 with a CLASSICAL runtime outer branch and a quantum middle one */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4;
  int q2 = cq_theta(7, .4); int r = 5;
  if (c > 2) { if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); } }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
