#include <stdlib.h>
/* r1A: zt_p1 (zt0b's runtime-seed, no region; the owner WITHDREW its accept) through a function pointer */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int t = q / 4; int r;
  int (*f)(int, double) = cq_theta_si32;
  if (t == s) r = f(t, .9); else r = f(s, .9); return cq_measure(r) + cq_measure(t); }
