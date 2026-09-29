#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
/* ANGLE-SELECT L1 route, TWO HOPS: the base z is the merge phi of a diamond whose condition
   (y > 50) is CLASSICAL at round 1 and becomes tainted only when y turns into the 6.5 %out
   rail -- so z is an untainted runtime base at round-1 classification (flag set), and the
   diamond producing it is a region only in ROUND 2. */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]), k = atoi(v[3]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x");
  int z = k; if (y > 50) z = k * 3 + 1; if (c > 2000) puts("y");
  int r; if (q2 > 7) r = cq_theta(z, .75); else r = cq_theta(z, .25); return cq_measure(r) + cq_measure(q); }
