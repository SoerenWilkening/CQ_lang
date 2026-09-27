#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .3); int r = 5; if (q2 > 3) r = h(q, m); return cq_measure(q2) + r; }
