#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = 0; for (int i = 0; i < 3; i++) t += (i + 1); int u = g(q, t); return cq_measure(u); }
