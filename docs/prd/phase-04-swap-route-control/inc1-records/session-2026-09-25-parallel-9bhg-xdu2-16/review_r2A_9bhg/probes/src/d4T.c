#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = (m + 1); int u = g(q, t); int q2 = cq_theta(n, .3); int r = (q2 > 3) ? u : 7; return cq_measure(r) + cq_measure(q2); }
