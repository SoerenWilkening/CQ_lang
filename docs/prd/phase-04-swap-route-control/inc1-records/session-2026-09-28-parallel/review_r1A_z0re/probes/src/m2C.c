#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
/* L1 via a VOLATILE local: store the 6.5 merge value, load it back as the prep seed */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x");
  volatile int vy = y; int s = vy;
  int r = s; if (q2 > 3) r = cq_theta(s, .2); return cq_measure(r); }
