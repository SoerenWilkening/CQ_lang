#include <stdlib.h>
/* r1A: a6 (nested) through a local function pointer */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  int (*f)(int, double) = cq_theta_si32;
  if (q2 > 3) { if (t == 5) r = f(t, .9); else r = f(5, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
