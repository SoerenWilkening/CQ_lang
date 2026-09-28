#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
/* L1 re-ask on a 6.5 %out seed whose region condition does NOT read the seed: a realizable in-place Ry */
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x"); int r = y; if (q2 > 7) r = cq_theta(y, .2); return cq_measure(r); }
