#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
int g(int a);   /* opaque, not const: a classical call on the 6.5 value */
/* L1 via an OPAQUE CALL: the seed is g(y), y a 6.5 merge value */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x");
  int s = g(y);
  int r = s; if (q2 > 3) r = cq_theta(s, .2); return cq_measure(r); }
