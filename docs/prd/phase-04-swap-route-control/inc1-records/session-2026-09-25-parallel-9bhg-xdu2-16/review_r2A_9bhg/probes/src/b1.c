#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = q + 1; int t = h(p, m); int r = cq_theta(q, .7); return t + cq_measure(r); }
