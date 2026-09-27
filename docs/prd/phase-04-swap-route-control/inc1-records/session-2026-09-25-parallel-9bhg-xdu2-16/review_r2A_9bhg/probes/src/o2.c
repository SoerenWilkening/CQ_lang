#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int p = q + 1; q = cq_theta(q, .4); int s = cq_theta(p, .2); int u = h2(q, m); return u + cq_measure(s); }
int main(int c, char **v) { int m = atoi(v[1]); return cq_measure(f(m)); }
