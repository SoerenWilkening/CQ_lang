#include <stdlib.h>
/* r1A: n9 in a TU that does NOT include CQ.h: the user declares the primitives himself
   (run with NOHDR=1). Outside the frontend contract (Rule 4: the frontend is CQ.h only), but the pass accepts it. */
int cq_theta_si32(int x, double angle);
int cq_measure_si32(int x);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta_si32(m, .5); int t = q / 4; int r;
  if (t == 5) r = cq_theta_si32(t, .9); else r = cq_theta_si32(5, .9);
  return cq_measure_si32(r) + cq_measure_si32(t); }
