#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
/* m1b without the prep region: unconditional theta on the loaded seed (oracle comparison) */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]), k = atoi(v[3]), j = atoi(v[4]); int q = cq_theta(m, .5);
  int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x");
  int buf[4] = {1, 2, 3, 4}; buf[k & 3] = y; int s = buf[j & 3];
  int r = cq_theta(s, .2); return cq_measure(r); }
