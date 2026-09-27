#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .3); int w = 3; if (q2 > 5) { printf("%d", q2); w = 7; } int u = h(q, w); return cq_measure(u); }
