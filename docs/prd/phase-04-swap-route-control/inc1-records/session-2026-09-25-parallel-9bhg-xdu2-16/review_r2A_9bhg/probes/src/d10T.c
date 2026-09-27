#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = (m + 1); int u = g(q, t); int w2 = g(u, t); return cq_measure(w2); }
