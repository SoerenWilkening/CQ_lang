#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int u = g(q, t); int u2 = g(q, t + 1); return cq_measure(u) + cq_measure(u2); }
