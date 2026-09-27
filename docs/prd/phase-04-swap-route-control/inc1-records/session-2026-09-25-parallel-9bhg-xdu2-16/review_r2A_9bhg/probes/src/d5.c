#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .3); int t = h(q, m); int r = q2; if (q2 > 3) r = q2 + g(q, t); return cq_measure(r); }
