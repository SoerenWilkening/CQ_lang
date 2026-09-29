#include <stdlib.h>
/* r1A: n9 through a LOCAL function pointer to cq_theta_si32 (-O1 promotes it to a direct call) */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  int (*f)(int, double) = cq_theta_si32;
  if (t == 5) r = f(t, .9); else r = f(5, .9);
  return cq_measure(r) + cq_measure(t); }
