#include <stdlib.h>
#include <stdio.h>
__attribute__((const)) int f(int a);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int y = 5; if (q > 3) y = f(n); if (c > 1000) puts("x"); int r; if (q2 + y > 7) r = cq_theta(y, .9); else r = cq_theta(y, .3); return cq_measure(r); }
