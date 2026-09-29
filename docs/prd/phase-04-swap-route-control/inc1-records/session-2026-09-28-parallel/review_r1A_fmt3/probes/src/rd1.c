#include <stdlib.h>
/* r1A: n9 with the user's OWN redeclaration of cq_theta_si32 AFTER CQ.h (no attribute) */
int cq_theta_si32(int x, double angle);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = cq_theta_si32(t, .9); else r = cq_theta_si32(5, .9);
  return cq_measure(r) + cq_measure(t); }
