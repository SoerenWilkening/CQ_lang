#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
/* L1 via MEMORY: a 6.5 merge value stored to memory at round 1 (classical), loaded back as the prep seed */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]), k = c; int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
  int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x");
  int buf[4] = {0, 0, 0, 0}; buf[k & 3] = y; int s = buf[(k * 5) & 3];
  int r = s; if (q2 > 3) r = cq_theta(s, .2); return cq_measure(r); }
