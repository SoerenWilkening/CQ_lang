#include <stdlib.h>
#include <stdio.h>
/* L1 route: seed is a 4.4 data-select result, block between */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int y = 5; if (q > 3) y = n + 9;
  if (c > 1000) puts("x");
  int r = y; if (q2 > 1) r = cq_theta(y, .2); return cq_measure(r); }
