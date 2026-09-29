#include <stdlib.h>
/* r1A: n9 through a static const function-pointer global */
static int (*const ROT)(int, double) = cq_theta_si32;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = ROT(t, .9); else r = ROT(5, .9);
  return cq_measure(r) + cq_measure(t); }
