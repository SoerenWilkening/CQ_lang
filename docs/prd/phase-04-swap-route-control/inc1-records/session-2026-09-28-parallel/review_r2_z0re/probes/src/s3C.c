#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
int g(int a);
/* ANGLE-SELECT L1 route: OPAQUE classical call on the 6.5 value */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]), k = c; (void)k; int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x");
  int s = g(y);
  int r; if (q2 > 7) r = cq_theta(s, .75); else r = cq_theta(s, .25); return cq_measure(r); }
