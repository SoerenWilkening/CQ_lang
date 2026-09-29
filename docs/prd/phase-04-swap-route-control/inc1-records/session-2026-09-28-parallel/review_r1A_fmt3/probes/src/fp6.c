#include <stdlib.h>
/* r1A: the Ry if/else on ONE register through a function pointer: does the old angle-select fold come back? */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(atoi(v[2]), .2);
  int (*f)(int, double) = cq_theta_si32;
  if (q > 3) p = f(p, .9); else p = f(p, .3);
  return cq_measure(p) + cq_measure(q); }
