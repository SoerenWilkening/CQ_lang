#include <stdlib.h>
#include <stdio.h>
/* s1C hand-inlined twin: f(n) = n + 100 */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int y = 5; if (q > 3) y = n + 100; if (c > 1000) puts("x");
  int r; if (q2 > 7) r = cq_theta(y, .75); else r = cq_theta(y, .25); return cq_measure(r) + cq_measure(q); }
