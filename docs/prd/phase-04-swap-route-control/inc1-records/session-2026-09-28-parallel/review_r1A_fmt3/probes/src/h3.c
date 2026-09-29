#include <stdlib.h>
/* r1A: a6 (nested region) through an EXTERN helper defined in another TU */
int rot(int x);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = rot(t); else r = rot(5); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
