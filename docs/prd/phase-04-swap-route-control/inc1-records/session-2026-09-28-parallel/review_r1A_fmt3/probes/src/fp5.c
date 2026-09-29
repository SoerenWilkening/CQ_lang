#include <stdlib.h>
/* r1A: n9 through a GENERIC higher-order helper (a rotation passed as a function pointer and inlined) */
typedef int (*rot_fn)(int, double);
static inline int apply(rot_fn f, int x, double a) { return f(x, a); }
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = apply(cq_theta_si32, t, .9); else r = apply(cq_theta_si32, 5, .9);
  return cq_measure(r) + cq_measure(t); }
