#include <stdlib.h>
/* r1A: n9 through (&cq_theta_si32)(...) and (*cq_theta_si32)(...) spellings */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = (&cq_theta_si32)(t, .9); else r = (*cq_theta_si32)(5, .9);
  return cq_measure(r) + cq_measure(t); }
