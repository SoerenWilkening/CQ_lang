#include <stdlib.h>
#include <stdio.h>
int h(int a, int k);
int h2(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; if (t > 3) cq_phi(.3); int u = h2(q, m); return u; }
int main(int c, char **v) { int m = atoi(v[1]); return cq_measure(f(m)); }
