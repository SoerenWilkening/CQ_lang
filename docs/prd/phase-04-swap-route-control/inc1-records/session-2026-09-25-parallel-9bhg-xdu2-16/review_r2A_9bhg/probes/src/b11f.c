#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int b, int k);
__attribute__((noinline)) int f(int m, int n) { int q = cq_theta(m, .5); int p = q + 1; int t = h(p, m); if (t > n) q = cq_theta(q, .7); return cq_measure(q); }
int main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }
